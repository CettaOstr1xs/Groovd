import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/lastfm_config.dart';

/// Service providing rich, granular genre tags for albums, tracks, and artists.
/// Enriches basic macro-genres with community tags from Last.fm, with an
/// automatic fallback to MusicBrainz's open encyclopedic genre taxonomy,
/// persistent disk caching, Cloud Firestore shared community cache, and an
/// instant synchronous curated knowledge base.
class GenreTagService {
  final http.Client _client;
  final String? lastFmApiKey;
  final FirebaseFirestore? _firestore;

  final Map<String, List<String>> _cache = {};
  final Map<String, String> _releaseDateCache = {};

  /// Pre-warmed curated canonical genres for top acclaimed and critical artists.
  /// Guarantees 0ms instantaneous display on first paint without network roundtrip.
  static final Map<String, List<String>> _curatedArtistGenres = {
    'have a nice life': ['SHOEGAZE', 'POST-PUNK', 'DARK AMBIENT', 'DRONE'],
    'giles corey': ['DARK FOLK', 'GOTHIC COUNTRY', 'SLOWCORE'],
    'planning for burial': ['DOOMGAZE', 'SLOWCORE', 'POST-METAL'],
    'radiohead': ['ART ROCK', 'ALTERNATIVE ROCK', 'ELECTRONIC', 'EXPERIMENTAL'],
    'my bloody valentine': ['SHOEGAZE', 'DREAM POP', 'NOISE POP'],
    'slowdive': ['SHOEGAZE', 'DREAM POP', 'AMBIENT'],
    'duster': ['SLOWCORE', 'SPACE ROCK', 'INDIE ROCK'],
    'the cure': ['POST-PUNK', 'GOTHIC ROCK', 'NEW WAVE'],
    'joy division': ['POST-PUNK', 'GOTHIC ROCK', 'COLDWAVE'],
    'new order': ['SYNTH-POP', 'POST-PUNK', 'DANCE-ROCK'],
    'depeche mode': ['SYNTH-POP', 'NEW WAVE', 'DARK WAVE'],
    'kendrick lamar': ['CONSCIOUS HIP HOP', 'WEST COAST HIP HOP', 'JAZZ RAP'],
    'deftones': ['ALTERNATIVE METAL', 'NU METAL', 'SHOEGAZE'],
    'black country, new road': ['POST-ROCK', 'ART ROCK', 'POST-PUNK'],
    'black midi': ['AVANT-PROG', 'MATH ROCK', 'POST-PUNK'],
    'title fight': ['POST-HARDCORE', 'SHOEGAZE', 'MELODIC HARDCORE'],
    'panchiko': ['INDIE ROCK', 'LO-FI', 'SHOEGAZE', 'TRIP HOP'],
    'neutral milk hotel': ['INDIE ROCK', 'LO-FI', 'PSYCHEDELIC FOLK'],
    'godspeed you! black emperor': ['POST-ROCK', 'DRONE', 'EXPERIMENTAL ROCK'],
    'american football': ['MIDWEST EMO', 'MATH ROCK', 'INDIE ROCK'],
    'car seat headrest': ['INDIE ROCK', 'LO-FI', 'POWER POP'],
    'alvvays': ['INDIE POP', 'DREAM POP', 'JANGLE POP'],
    'cocteau twins': ['DREAM POP', 'ETHEREAL WAVE', 'POST-PUNK'],
    'swans': ['POST-ROCK', 'NOISE ROCK', 'EXPERIMENTAL ROCK'],
    'pink floyd': ['PROGRESSIVE ROCK', 'PSYCHEDELIC ROCK', 'ART ROCK'],
    'nirvana': ['GRUNGE', 'ALTERNATIVE ROCK', 'PUNK ROCK'],
    'the smiths': ['JANGLE POP', 'POST-PUNK', 'INDIE POP'],
    'tyler, the creator': ['HIP HOP', 'NEO-SOUL', 'EXPERIMENTAL HIP HOP'],
    'kanye west': ['HIP HOP', 'PROGRESSIVE RAP', 'CHIPMUNK SOUL'],
    'frank ocean': ['CONTEMPORARY R&B', 'NEO-SOUL', 'ART POP'],
    'lana del rey': ['SADCORE', 'BAROQUE POP', 'DREAM POP'],
    'mitski': ['INDIE ROCK', 'ART POP', 'CHAMBER POP'],
    'david bowie': ['GLAM ROCK', 'ART ROCK', 'POP ROCK'],
    'the beatles': ['ROCK', 'POP', 'PSYCHEDELIC ROCK'],
    'mf doom': ['UNDERGROUND HIP HOP', 'ABSTRACT HIP HOP', 'BOOM BAP'],
    'madvillain': ['UNDERGROUND HIP HOP', 'ABSTRACT HIP HOP', 'BOOM BAP'],
    'playboi carti': ['RAGE', 'TRAP', 'CLOUD RAP'],
    'mac miller': ['CONSCIOUS HIP HOP', 'JAZZ RAP', 'CLOUD RAP'],
    'kino': ['POST-PUNK', 'NEW WAVE', 'SOVIET ROCK'],
    'кино': ['POST-PUNK', 'NEW WAVE', 'SOVIET ROCK'],
    'tokyo shoegazer': ['SHOEGAZE', 'NOISE POP', 'POST-ROCK'],
    'sweet trip': ['GLITCH POP', 'SHOEGAZE', 'DREAM POP'],
    'slint': ['POST-ROCK', 'MATH ROCK', 'INDIE ROCK'],
    'interpol': ['POST-PUNK REVIVAL', 'INDIE ROCK'],
    'the strokes': ['GARAGE ROCK REVIVAL', 'POST-PUNK REVIVAL', 'INDIE ROCK'],
    'arctic monkeys': ['INDIE ROCK', 'GARAGE ROCK', 'POST-PUNK REVIVAL'],
    'daft punk': ['FRENCH HOUSE', 'DISCO', 'SYNTH-POP'],
    'aphex twin': ['IDM', 'AMBIENT TECHNO', 'DRILL N BASS'],
    'massive attack': ['TRIP HOP', 'DOWNTEMPO', 'ELECTRONICA'],
    'portishead': ['TRIP HOP', 'DOWNTEMPO', 'ART POP'],
    'bjork': ['ART POP', 'ELECTRONICA', 'EXPERIMENTAL'],
    'björk': ['ART POP', 'ELECTRONICA', 'EXPERIMENTAL'],
    'talking heads': ['NEW WAVE', 'POST-PUNK', 'ART PUNK'],
    'sonic youth': ['NOISE ROCK', 'ALTERNATIVE ROCK', 'POST-PUNK'],
    'smashing pumpkins': ['ALTERNATIVE ROCK', 'GRUNGE', 'DREAM POP'],
    'the smashing pumpkins': ['ALTERNATIVE ROCK', 'GRUNGE', 'DREAM POP'],
    'nine inch nails': ['INDUSTRIAL ROCK', 'INDUSTRIAL METAL', 'DARK AMBIENT'],
    'boards of canada': ['IDM', 'DOWNTEMPO', 'HAUNTOLOGY'],
    'burial': ['FUTURE GARAGE', 'DUBSTEP', 'AMBIENT'],
    'death grips': ['EXPERIMENTAL HIP HOP', 'INDUSTRIAL HIP HOP', 'HARDCORE PUNK'],
    'jpegmafia': ['EXPERIMENTAL HIP HOP', 'INDUSTRIAL HIP HOP', 'GLITCH HOP'],
    'charli xcx': ['HYPERPOP', 'ELECTROPOP', 'DANCE-POP'],
    'fka twigs': ['ART POP', 'AVANT-GARDE R&B', 'TRIP HOP'],
    'sza': ['CONTEMPORARY R&B', 'NEO-SOUL', 'POP'],
    'billie eilish': ['ELECTROPOP', 'DARK POP', 'ART POP'],
    'lorde': ['ART POP', 'ELECTROPOP', 'INDIE POP'],
    'phoebe bridgers': ['INDIE FOLK', 'INDIE ROCK', 'EMO'],
    'big thief': ['INDIE FOLK', 'INDIE ROCK', 'FOLK ROCK'],
    'fleet foxes': ['INDIE FOLK', 'CHAMBER POP', 'FOLK ROCK'],
    'sufjan stevens': ['INDIE FOLK', 'BAROQUE POP', 'ELECTRONICA'],
    'tame impala': ['PSYCHEDELIC POP', 'NEO-PSYCHEDELIA', 'SYNTH-POP'],
    'beach house': ['DREAM POP', 'SHOEGAZE', 'INDIE POP'],
    'cigarettes after sex': ['DREAM POP', 'SLOWCORE', 'AMBIENT POP'],
    'mac demarco': ['SLACKER ROCK', 'JANGLE POP', 'INDIE ROCK'],
    'steve lacy': ['NEO-SOUL', 'LO-FI R&B', 'INDIE ROCK'],
    'childish gambino': ['PSYCHEDELIC SOUL', 'FUNK', 'HIP HOP'],
    'the weeknd': ['SYNTH-POP', 'CONTEMPORARY R&B', 'DARK WAVE'],
    'gorillaz': ['ALTERNATIVE ROCK', 'TRIP HOP', 'HIP HOP'],
    'mgmt': ['NEO-PSYCHEDELIA', 'INDIE POP', 'SYNTH-POP'],
    'glass animals': ['PSYCHEDELIC POP', 'INDIE ROCK', 'TRIP HOP'],
    'two door cinema club': ['INDIE ROCK', 'DANCE-PUNK', 'POST-PUNK REVIVAL'],
    'phoenix': ['INDIE POP', 'SYNTH-POP', 'FRENCH INDIE'],
    'vampire weekend': ['INDIE POP', 'CHAMBER POP', 'AFROPOP'],
    'the national': ['INDIE ROCK', 'POST-PUNK REVIVAL', 'CHAMBER ROCK'],
    'bon iver': ['INDIE FOLK', 'ART POP', 'FOLKTRONICA'],
    'sigur ros': ['POST-ROCK', 'AMBIENT', 'DREAM POP'],
    'sigur rós': ['POST-ROCK', 'AMBIENT', 'DREAM POP'],
    'mogwai': ['POST-ROCK', 'INSTRUMENTAL ROCK', 'SHOEGAZE'],
    'explosions in the sky': ['POST-ROCK', 'INSTRUMENTAL ROCK'],
    'this will destroy you': ['POST-ROCK', 'AMBIENT', 'DRONE'],
    'russian circles': ['POST-METAL', 'POST-ROCK', 'INSTRUMENTAL METAL'],
    'tool': ['PROGRESSIVE METAL', 'ART ROCK', 'ALTERNATIVE METAL'],
    'mastodon': ['PROGRESSIVE METAL', 'SLUDGE METAL', 'STONER ROCK'],
    'gojira': ['PROGRESSIVE DEATH METAL', 'GROOVE METAL', 'TECHNICAL DEATH METAL'],
    'opeth': ['PROGRESSIVE METAL', 'PROGRESSIVE ROCK', 'DEATH METAL'],
    'queens of the stone age': ['STONER ROCK', 'DESERT ROCK', 'ALTERNATIVE ROCK'],
    'black sabbath': ['HEAVY METAL', 'DOOM METAL', 'HARD ROCK'],
    'metallica': ['THRASH METAL', 'HEAVY METAL', 'SPEED METAL'],
    'slipknot': ['NU METAL', 'ALTERNATIVE METAL', 'GROOVE METAL'],
    'korn': ['NU METAL', 'ALTERNATIVE METAL'],
    'system of a down': ['ALTERNATIVE METAL', 'NU METAL', 'HARD ROCK'],
    'linkin park': ['NU METAL', 'ALTERNATIVE ROCK', 'RAP ROCK'],
    'rage against the machine': ['RAP METAL', 'FUNK METAL', 'ALTERNATIVE METAL'],
    'soundgarden': ['GRUNGE', 'HEAVY METAL', 'ALTERNATIVE ROCK'],
    'alice in chains': ['GRUNGE', 'SLUDGE METAL', 'ALTERNATIVE METAL'],
    'pearl jam': ['GRUNGE', 'ALTERNATIVE ROCK', 'HARD ROCK'],
    'green day': ['PUNK ROCK', 'POP PUNK', 'ALTERNATIVE ROCK'],
    'blink-182': ['POP PUNK', 'SKATE PUNK', 'ALTERNATIVE ROCK'],
    'paramore': ['POP PUNK', 'EMO POP', 'ALTERNATIVE ROCK', 'NEW WAVE'],
    'my chemical romance': ['EMO', 'POST-HARDCORE', 'POP PUNK', 'GLAM ROCK'],
    'fugazi': ['POST-HARDCORE', 'DISCHORD PUNK', 'ART PUNK'],
    'the velvet underground': ['ART ROCK', 'PROTO-PUNK', 'EXPERIMENTAL ROCK'],
    'television': ['ART PUNK', 'POST-PUNK', 'PROTOPUNK'],
    'bauhaus': ['GOTHIC ROCK', 'POST-PUNK', 'DARK WAVE'],
    'siouxsie and the banshees': ['POST-PUNK', 'GOTHIC ROCK', 'NEW WAVE'],
    'the sisters of mercy': ['GOTHIC ROCK', 'DARK WAVE', 'POST-PUNK'],
    'the jesus and mary chain': ['NOISE POP', 'SHOEGAZE', 'POST-PUNK'],
    'ride': ['SHOEGAZE', 'NEO-PSYCHEDELIA', 'DREAM POP'],
    'lush': ['SHOEGAZE', 'DREAM POP', 'BRITPOP'],
    'drop nineteens': ['SHOEGAZE', 'NOISE POP', 'INDIE ROCK'],
    'fishmans': ['DREAM POP', 'DUB', 'NEO-PSYCHEDELIA', 'SHOEGAZE'],
    'parannoul': ['SHOEGAZE', 'MIDWEST EMO', 'NOISE POP', 'LO-FI'],
    'weatherday': ['LO-FI', 'EMO', 'NOISE POP'],
  };

  /// Pre-warmed curated canonical genres for top iconic and legendary albums.
  static final Map<String, List<String>> _curatedAlbumGenres = {
    'deathconsciousness': ['SHOEGAZE', 'POST-PUNK', 'DARK AMBIENT', 'DRONE'],
    'ok computer': ['ART ROCK', 'ALTERNATIVE ROCK', 'EXPERIMENTAL ROCK'],
    'kid a': ['ELECTRONIC', 'ART ROCK', 'EXPERIMENTAL', 'IDM'],
    'in rainbows': ['ART ROCK', 'ALTERNATIVE ROCK', 'ART POP'],
    'the bends': ['ALTERNATIVE ROCK', 'BRITPOP', 'POST-GRUNGE'],
    'amnesiac': ['ART ROCK', 'EXPERIMENTAL', 'ELECTRONIC'],
    'a moon shaped pool': ['ART ROCK', 'CHAMBER POP', 'AMBIENT'],
    'loveless': ['SHOEGAZE', 'NOISE POP', 'DREAM POP'],
    'isn\'t anything': ['SHOEGAZE', 'NOISE POP', 'POST-PUNK'],
    'souvlaki': ['SHOEGAZE', 'DREAM POP', 'AMBIENT'],
    'just for a day': ['SHOEGAZE', 'DREAM POP', 'ETHEREAL WAVE'],
    'pygmalion': ['AMBIENT', 'POST-ROCK', 'DREAM POP'],
    'stratosphere': ['SLOWCORE', 'SPACE ROCK', 'INDIE ROCK'],
    'contemporary movement': ['SLOWCORE', 'INDIE ROCK', 'SPACE ROCK'],
    'disintegration': ['GOTHIC ROCK', 'POST-PUNK', 'DREAM POP'],
    'pornography': ['GOTHIC ROCK', 'POST-PUNK', 'DARK WAVE'],
    'unknown pleasures': ['POST-PUNK', 'GOTHIC ROCK', 'COLDWAVE'],
    'closer': ['POST-PUNK', 'GOTHIC ROCK', 'COLDWAVE'],
    'to pimp a butterfly': ['CONSCIOUS HIP HOP', 'JAZZ RAP', 'FUNK', 'SOUL'],
    'good kid, m.a.a.d city': ['CONSCIOUS HIP HOP', 'WEST COAST HIP HOP', 'GANGSTA RAP'],
    'damn.': ['CONSCIOUS HIP HOP', 'TRAP', 'WEST COAST HIP HOP'],
    'around the fur': ['ALTERNATIVE METAL', 'NU METAL', 'POST-HARDCORE'],
    'white pony': ['ALTERNATIVE METAL', 'ART ROCK', 'TRIP HOP', 'SHOEGAZE'],
    'deftones': ['ALTERNATIVE METAL', 'POST-METAL', 'SHOEGAZE'],
    'diamond eyes': ['ALTERNATIVE METAL', 'POST-METAL', 'POST-HARDCORE'],
    'koi no yokan': ['ALTERNATIVE METAL', 'DREAM POP', 'SHOEGAZE'],
    'ants from up there': ['ART ROCK', 'POST-ROCK', 'CHAMBER POP'],
    'for the first time': ['POST-PUNK', 'POST-ROCK', 'MATH ROCK'],
    'floral green': ['POST-HARDCORE', 'SHOEGAZE', 'PUNK ROCK'],
    'shed': ['POST-HARDCORE', 'MELODIC HARDCORE', 'PUNK ROCK'],
    'hyperview': ['SHOEGAZE', 'DREAM POP', 'POST-HARDCORE'],
    'd>e>a>t>h>m>e>t>a>l': ['INDIE ROCK', 'LO-FI', 'SHOEGAZE', 'TRIP HOP'],
    'in the aeroplane over the sea': ['INDIE ROCK', 'PSYCHEDELIC FOLK', 'LO-FI'],
    'lift your skinny fists like antennas to heaven': ['POST-ROCK', 'DRONE', 'EXPERIMENTAL ROCK'],
    'f# a# infinity': ['POST-ROCK', 'DRONE', 'DARK AMBIENT'],
    'twin fantasy': ['INDIE ROCK', 'LO-FI', 'POWER POP'],
    'heaven or las vegas': ['DREAM POP', 'ETHEREAL WAVE'],
    'treasure': ['DREAM POP', 'ETHEREAL WAVE', 'POST-PUNK'],
    'the dark side of the moon': ['PROGRESSIVE ROCK', 'PSYCHEDELIC ROCK', 'ART ROCK'],
    'wish you were here': ['PROGRESSIVE ROCK', 'ART ROCK', 'PSYCHEDELIC ROCK'],
    'animals': ['PROGRESSIVE ROCK', 'ART ROCK', 'HARD ROCK'],
    'nevermind': ['GRUNGE', 'ALTERNATIVE ROCK', 'PUNK ROCK'],
    'in utero': ['GRUNGE', 'NOISE ROCK', 'ALTERNATIVE ROCK'],
    'the queen is dead': ['JANGLE POP', 'POST-PUNK', 'INDIE POP'],
    'meat is murder': ['POST-PUNK', 'JANGLE POP', 'INDIE ROCK'],
    'igor': ['NEO-SOUL', 'FUNK', 'EXPERIMENTAL HIP HOP'],
    'call me if you get lost': ['HIP HOP', 'BOOM BAP', 'NEO-SOUL'],
    'flower boy': ['NEO-SOUL', 'HIP HOP', 'JAZZ RAP'],
    'my beautiful dark twisted fantasy': ['PROGRESSIVE RAP', 'HIP HOP', 'ART POP'],
    'the college dropout': ['CHIPMUNK SOUL', 'CONSCIOUS HIP HOP', 'BOOM BAP'],
    'late registration': ['CHIPMUNK SOUL', 'ORCHESTRAL RAP', 'BOOM BAP'],
    'graduation': ['SYNTH-POP', 'ELECTRO-RAP', 'ARENA RAP'],
    '808s & heartbreak': ['SYNTH-POP', 'ELECTROPOP', 'EMO RAP'],
    'yeezus': ['INDUSTRIAL HIP HOP', 'EXPERIMENTAL HIP HOP', 'ELECTRO'],
    'blonde': ['ART POP', 'CONTEMPORARY R&B', 'NEO-SOUL'],
    'channel orange': ['CONTEMPORARY R&B', 'NEO-SOUL', 'POP'],
    'madvillainy': ['UNDERGROUND HIP HOP', 'ABSTRACT HIP HOP', 'BOOM BAP'],
    'mm.. food': ['UNDERGROUND HIP HOP', 'BOOM BAP', 'ABSTRACT HIP HOP'],
    'die lit': ['RAGE', 'TRAP', 'CLOUD RAP'],
    'whole lotta red': ['RAGE', 'TRAP', 'PUNK RAP'],
    'swimming': ['CONSCIOUS HIP HOP', 'NEO-SOUL', 'JAZZ RAP'],
    'circles': ['NEO-SOUL', 'INDIE POP', 'BEDROOM POP'],
    'gruppa krovi': ['POST-PUNK', 'NEW WAVE', 'SOVIET ROCK'],
    'группа крови': ['POST-PUNK', 'NEW WAVE', 'SOVIET ROCK'],
    'звезда по имени солнце': ['POST-PUNK', 'NEW WAVE', 'SOVIET ROCK'],
    'zvezda po imeni solntse': ['POST-PUNK', 'NEW WAVE', 'SOVIET ROCK'],
    'velocity : design : comfort': ['GLITCH POP', 'SHOEGAZE', 'DREAM POP', 'IDM'],
    'spiderland': ['POST-ROCK', 'MATH ROCK', 'INDIE ROCK'],
    'turn on the bright lights': ['POST-PUNK REVIVAL', 'INDIE ROCK'],
    'is this it': ['GARAGE ROCK REVIVAL', 'POST-PUNK REVIVAL', 'INDIE ROCK'],
    'room on fire': ['GARAGE ROCK REVIVAL', 'POST-PUNK REVIVAL', 'INDIE ROCK'],
    'whatever people say i am, that\'s what i\'m not': ['INDIE ROCK', 'GARAGE ROCK', 'POST-PUNK REVIVAL'],
    'favourite worst nightmare': ['INDIE ROCK', 'POST-PUNK REVIVAL', 'GARAGE ROCK'],
    'am': ['INDIE ROCK', 'GARAGE ROCK', 'R&B'],
    'discovery': ['FRENCH HOUSE', 'DISCO', 'SYNTH-POP'],
    'homework': ['FRENCH HOUSE', 'TECHNO', 'ACID HOUSE'],
    'random access memories': ['DISCO', 'FUNK', 'PROGRESSIVE POP'],
    'selected ambient works 85-92': ['AMBIENT TECHNO', 'IDM', 'DOWNTEMPO'],
    'richard d. james album': ['DRILL N BASS', 'IDM', 'EXPERIMENTAL ELECTRONIC'],
    'mezzanine': ['TRIP HOP', 'DOWNTEMPO', 'ELECTRONICA'],
    'blue lines': ['TRIP HOP', 'DOWNTEMPO', 'HIP HOP'],
    'dummy': ['TRIP HOP', 'DOWNTEMPO', 'ART POP'],
    'portishead': ['TRIP HOP', 'DOWNTEMPO', 'TURNTABLISM'],
    'third': ['EXPERIMENTAL ROCK', 'KRAUTROCK', 'TRIP HOP'],
    'homogenic': ['ART POP', 'ELECTRONICA', 'GLITCH'],
    'vespertine': ['ART POP', 'GLITCH POP', 'MICROHOUSE'],
    'post': ['ART POP', 'TRIP HOP', 'ELECTRONICA'],
    'remain in light': ['NEW WAVE', 'AFROBEAT', 'POST-PUNK', 'FUNK'],
    'daydream nation': ['NOISE ROCK', 'ALTERNATIVE ROCK', 'POST-PUNK'],
    'goo': ['ALTERNATIVE ROCK', 'NOISE ROCK', 'GRUNGE'],
    'siamese dream': ['ALTERNATIVE ROCK', 'SHOEGAZE', 'GRUNGE'],
    'mellon collie and the infinite sadness': ['ALTERNATIVE ROCK', 'ART ROCK', 'GRUNGE'],
    'violator': ['SYNTH-POP', 'NEW WAVE', 'DARK WAVE'],
    'music for the masses': ['SYNTH-POP', 'NEW WAVE', 'DARK WAVE'],
    'the downward spiral': ['INDUSTRIAL ROCK', 'INDUSTRIAL METAL', 'DARK AMBIENT'],
    'the fragile': ['INDUSTRIAL ROCK', 'ART ROCK', 'DARK AMBIENT'],
    'music has the right to children': ['IDM', 'DOWNTEMPO', 'HAUNTOLOGY'],
    'geogaddi': ['IDM', 'HAUNTOLOGY', 'PSYCHEDELIA'],
    'untrue': ['FUTURE GARAGE', 'DUBSTEP', 'AMBIENT'],
    'the money store': ['EXPERIMENTAL HIP HOP', 'INDUSTRIAL HIP HOP'],
    'exmilitary': ['EXPERIMENTAL HIP HOP', 'HARDCORE HIP HOP', 'NOISE'],
    'bottomless pit': ['EXPERIMENTAL HIP HOP', 'NOISE ROCK', 'DIGITAL HARDCORE'],
    'scaring the hoes': ['EXPERIMENTAL HIP HOP', 'INDUSTRIAL HIP HOP', 'GLITCH HOP'],
    'lp!': ['EXPERIMENTAL HIP HOP', 'GLITCH HOP', 'CLOUD RAP'],
    'brat': ['HYPERPOP', 'ELECTROPOP', 'CLUB DANCE'],
    'how i\'m feeling now': ['HYPERPOP', 'ELECTROPOP', 'FUTUREPOP'],
    'magdalene': ['ART POP', 'AVANT-GARDE R&B', 'ELECTRONIC'],
    'caprisongs': ['AVANT-GARDE R&B', 'AFROBEATS', 'ART POP'],
    'sos': ['CONTEMPORARY R&B', 'POP', 'HIP HOP'],
    'ctrl': ['CONTEMPORARY R&B', 'NEO-SOUL', 'INDIE POP'],
    'when we all fall asleep, where do we go?': ['DARK POP', 'ELECTROPOP', 'ART POP'],
    'happier than ever': ['ART POP', 'INDIE POP', 'DOWNTEMPO'],
    'hit me hard and soft': ['ART POP', 'SYNTH-POP', 'CHAMBER POP'],
    'melodrama': ['ART POP', 'ELECTROPOP', 'DANCE-POP'],
    'pure heroine': ['ART POP', 'ELECTROPOP', 'INDIE POP'],
    'punisher': ['INDIE FOLK', 'INDIE ROCK', 'EMO'],
    'stranger in the alps': ['INDIE FOLK', 'SINGER-SONGWRITER', 'INDIE ROCK'],
    'the record': ['INDIE ROCK', 'INDIE FOLK', 'FOLK ROCK'],
    'dragon new warm mountain i believe in you': ['INDIE FOLK', 'FOLK ROCK', 'COUNTRY ROCK'],
    'masterpiece': ['INDIE ROCK', 'FOLK ROCK', 'LO-FI'],
    'helplessness blues': ['INDIE FOLK', 'CHAMBER POP', 'FOLK ROCK'],
    'fleet foxes': ['INDIE FOLK', 'BAROQUE POP', 'FOLK ROCK'],
    'illinois': ['INDIE FOLK', 'BAROQUE POP', 'CHAMBER POP'],
    'carrie & lowell': ['INDIE FOLK', 'ACOUSTIC', 'SLOWCORE'],
    'currents': ['PSYCHEDELIC POP', 'SYNTH-POP', 'DISCO'],
    'lonerism': ['NEO-PSYCHEDELIA', 'PSYCHEDELIC ROCK', 'SPACE ROCK'],
    'innerspeaker': ['PSYCHEDELIC ROCK', 'NEO-PSYCHEDELIA', 'INDIE ROCK'],
    'bloom': ['DREAM POP', 'SHOEGAZE', 'INDIE POP'],
    'teen dream': ['DREAM POP', 'INDIE POP', 'LO-FI'],
    'depression cherry': ['DREAM POP', 'SHOEGAZE', 'AMBIENT POP'],
    'once twice melody': ['DREAM POP', 'CHAMBER POP', 'SHOEGAZE'],
    'cigarettes after sex': ['DREAM POP', 'SLOWCORE', 'AMBIENT POP'],
    'cry': ['DREAM POP', 'SLOWCORE', 'AMBIENT POP'],
    'salad days': ['SLACKER ROCK', 'JANGLE POP', 'INDIE ROCK'],
    '2': ['SLACKER ROCK', 'LO-FI', 'JANGLE POP'],
    'gemini rights': ['NEO-SOUL', 'FUNK', 'INDIE ROCK'],
    '\"awaken, my love!\"': ['PSYCHEDELIC SOUL', 'FUNK', 'R&B'],
    'because the internet': ['HIP HOP', 'ALTERNATIVE R&B', 'INDIE'],
    'after hours': ['SYNTH-POP', 'CONTEMPORARY R&B', 'NEW WAVE'],
    'dawn fm': ['SYNTH-POP', 'DANCE-POP', 'DISCO'],
    'trilogy': ['DARK WAVE', 'ALTERNATIVE R&B', 'CONTEMPORARY R&B'],
    'demon days': ['ALTERNATIVE ROCK', 'TRIP HOP', 'HIP HOP'],
    'plastic beach': ['SYNTH-POP', 'ELECTROPOP', 'TRIP HOP'],
    'little dark age': ['SYNTH-POP', 'INDIE POP', 'DARK WAVE'],
    'oracular spectacular': ['NEO-PSYCHEDELIA', 'INDIE POP', 'SYNTH-POP'],
    'torches': ['INDIE POP', 'ELECTROPOP', 'NEO-PSYCHEDELIA'],
    'zaba': ['PSYCHEDELIC POP', 'TRIP HOP', 'INDIE POP'],
    'how to be a human being': ['INDIE POP', 'ART POP', 'PSYCHEDELIC POP'],
    'tourist history': ['INDIE ROCK', 'DANCE-PUNK'],
    'wolfgang amadeus phoenix': ['INDIE POP', 'SYNTH-POP'],
    'modern vampires of the city': ['INDIE POP', 'CHAMBER POP', 'ART POP'],
    'boxer': ['INDIE ROCK', 'POST-PUNK REVIVAL'],
    'high violet': ['INDIE ROCK', 'POST-PUNK REVIVAL', 'CHAMBER ROCK'],
    'for emma, forever ago': ['INDIE FOLK', 'ACOUSTIC', 'SINGER-SONGWRITER'],
    '22, a million': ['FOLKTRONICA', 'GLITCH', 'ART POP'],
    'agaetis byrjun': ['POST-ROCK', 'DREAM POP', 'AMBIENT'],
    'ágætis byrjun': ['POST-ROCK', 'DREAM POP', 'AMBIENT'],
    'young team': ['POST-ROCK', 'INSTRUMENTAL ROCK', 'SHOEGAZE'],
    'the earth is not a cold dead place': ['POST-ROCK', 'INSTRUMENTAL ROCK'],
    'lateralus': ['PROGRESSIVE METAL', 'ART ROCK'],
    'aenima': ['PROGRESSIVE METAL', 'ALTERNATIVE METAL'],
    'ænima': ['PROGRESSIVE METAL', 'ALTERNATIVE METAL'],
    '10,000 days': ['PROGRESSIVE METAL', 'ALTERNATIVE METAL'],
    'mer de noms': ['ALTERNATIVE ROCK', 'ART ROCK'],
    'crack the skye': ['PROGRESSIVE METAL', 'SLUDGE METAL'],
    'from mars to sirius': ['PROGRESSIVE DEATH METAL', 'TECHNICAL DEATH METAL'],
    'the way of all flesh': ['PROGRESSIVE DEATH METAL', 'GROOVE METAL'],
    'blackwater park': ['PROGRESSIVE METAL', 'DEATH METAL'],
    'ghost reveries': ['PROGRESSIVE METAL', 'PROGRESSIVE ROCK'],
    'songs for the deaf': ['STONER ROCK', 'DESERT ROCK', 'HARD ROCK'],
    '...like clockwork': ['ALTERNATIVE ROCK', 'STONER ROCK', 'DESERT ROCK'],
    'master of reality': ['DOOM METAL', 'HEAVY METAL', 'STONER ROCK'],
    'paranoid': ['HEAVY METAL', 'HARD ROCK'],
    'black sabbath': ['DOOM METAL', 'HEAVY METAL', 'BLUES ROCK'],
    'master of puppets': ['THRASH METAL', 'HEAVY METAL'],
    'ride the lightning': ['THRASH METAL', 'HEAVY METAL'],
    '...and justice for all': ['THRASH METAL', 'PROGRESSIVE METAL'],
    'iowa': ['NU METAL', 'EXTREME METAL', 'ALTERNATIVE METAL'],
    'slipknot': ['NU METAL', 'ALTERNATIVE METAL'],
    'follow the leader': ['NU METAL', 'ALTERNATIVE METAL'],
    'toxicity': ['ALTERNATIVE METAL', 'NU METAL', 'HARD ROCK'],
    'system of a down': ['ALTERNATIVE METAL', 'NU METAL'],
    'hybrid theory': ['NU METAL', 'RAP ROCK', 'ALTERNATIVE ROCK'],
    'meteora': ['NU METAL', 'ALTERNATIVE ROCK'],
    'rage against the machine': ['RAP METAL', 'FUNK METAL'],
    'evil empire': ['RAP METAL', 'FUNK METAL'],
    'the battle of los angeles': ['RAP METAL', 'FUNK METAL'],
    'superunknown': ['GRUNGE', 'ALTERNATIVE ROCK', 'HEAVY METAL'],
    'badmotorfinger': ['GRUNGE', 'HEAVY METAL', 'ALTERNATIVE ROCK'],
    'dirt': ['GRUNGE', 'SLUDGE METAL', 'ALTERNATIVE METAL'],
    'facelift': ['GRUNGE', 'HEAVY METAL', 'ALTERNATIVE METAL'],
    'jar of flies': ['ACOUSTIC ROCK', 'GRUNGE', 'ALTERNATIVE ROCK'],
    'ten': ['GRUNGE', 'HARD ROCK'],
    'vs.': ['GRUNGE', 'HARD ROCK', 'PUNK ROCK'],
    'dookie': ['POP PUNK', 'PUNK ROCK', 'ALTERNATIVE ROCK'],
    'american idiot': ['POP PUNK', 'PUNK ROCK', 'ROCK OPERA'],
    'enema of the state': ['POP PUNK', 'SKATE PUNK'],
    'take off your pants and jacket': ['POP PUNK', 'SKATE PUNK'],
    'riot!': ['POP PUNK', 'EMO POP', 'ALTERNATIVE ROCK'],
    'brand new eyes': ['POP PUNK', 'ALTERNATIVE ROCK', 'EMO'],
    'after laughter': ['NEW WAVE', 'SYNTH-POP', 'INDIE POP'],
    'this is why': ['POST-PUNK', 'DANCE-PUNK', 'INDIE ROCK'],
    'the black parade': ['EMO', 'POST-HARDCORE', 'GLAM ROCK'],
    'three cheers for sweet revenge': ['POST-HARDCORE', 'EMO', 'PUNK ROCK'],
    'repeater': ['POST-HARDCORE', 'DISCHORD PUNK'],
    '13 songs': ['POST-HARDCORE', 'DISCHORD PUNK'],
    'the velvet underground & nico': ['ART ROCK', 'PROTO-PUNK', 'EXPERIMENTAL'],
    'white light/white heat': ['NOISE ROCK', 'PROTO-PUNK', 'GARAGE ROCK'],
    'the velvet underground': ['FOLK ROCK', 'ART ROCK', 'INDIE ROCK'],
    'loaded': ['CLASSIC ROCK', 'POP ROCK'],
    'marquee moon': ['ART PUNK', 'POST-PUNK', 'TELEVISION'],
    'in the flat field': ['GOTHIC ROCK', 'POST-PUNK'],
    'psychocandy': ['NOISE POP', 'SHOEGAZE', 'POST-PUNK'],
    'darklands': ['POST-PUNK', 'INDIE POP', 'JANGLE POP'],
    'nowhere': ['SHOEGAZE', 'NEO-PSYCHEDELIA'],
    'going blank again': ['SHOEGAZE', 'POWER POP', 'NEO-PSYCHEDELIA'],
    'spooky': ['SHOEGAZE', 'DREAM POP'],
    'split': ['SHOEGAZE', 'DREAM POP', 'BRITPOP'],
    'delaware': ['SHOEGAZE', 'NOISE POP', 'INDIE ROCK'],
    'long season': ['DREAM POP', 'NEO-PSYCHEDELIA', 'DUB', 'SHOEGAZE'],
    'uchu nippon setagaya': ['DREAM POP', 'DUB', 'SHOEGAZE'],
    'kuchu camp': ['DUB', 'DREAM POP', 'INDIE POP'],
    'to see the next part of the dream': ['SHOEGAZE', 'MIDWEST EMO', 'NOISE POP', 'LO-FI'],
    'after the night': ['SHOEGAZE', 'POST-ROCK', 'NOISE POP'],
    'after the magic': ['SHOEGAZE', 'POST-ROCK', 'CHAMBER POP'],
    'come in': ['LO-FI', 'EMO', 'NOISE POP', 'MIDWEST EMO'],
  };

  /// Verified encyclopedic original release dates for iconic releases.
  /// Guarantees instant 0ms lookup without relying on network or reissue dates.
  static final Map<String, String> _curatedReleaseDates = {
    'deathconsciousness': '2008-01-24',
    'ok computer': '1997-05-21',
    'kid a': '2000-10-02',
    'in rainbows': '2007-10-10',
    'the bends': '1995-03-13',
    'loveless': '1991-11-04',
    'souvlaki': '1993-05-17',
    'stratosphere': '1998-02-24',
    'disintegration': '1989-05-02',
    'pornography': '1982-05-04',
    'unknown pleasures': '1979-06-15',
    'closer': '1980-07-18',
    'to pimp a butterfly': '2015-03-15',
    'good kid, m.a.a.d city': '2012-10-22',
    'damn.': '2017-04-14',
    'around the fur': '1997-10-28',
    'white pony': '2000-06-20',
    'ants from up there': '2022-02-04',
    'for the first time': '2021-02-05',
    'floral green': '2012-09-18',
    'd>e>a>t>h>m>e>t>a>l': '2000-06-01',
    'in the aeroplane over the sea': '1998-02-10',
    'lift your skinny fists like antennas to heaven': '2000-10-09',
    'f# a# infinity': '1997-08-14',
    'twin fantasy': '2011-11-02',
    'heaven or las vegas': '1990-09-17',
    'the dark side of the moon': '1973-03-01',
    'wish you were here': '1975-09-12',
    'nevermind': '1991-09-24',
    'in utero': '1993-09-21',
    'the queen is dead': '1986-06-16',
    'igor': '2019-05-17',
    'flower boy': '2017-07-21',
    'my beautiful dark twisted fantasy': '2010-11-22',
    'blonde': '2016-08-20',
    'channel orange': '2012-07-10',
    'madvillainy': '2004-03-23',
    'die lit': '2018-05-11',
    'swimming': '2018-08-03',
    'gruppa krovi': '1988-01-05',
    'группа крови': '1988-01-05',
    'velocity : design : comfort': '2003-05-27',
    'spiderland': '1991-03-27',
    'turn on the bright lights': '2002-08-20',
    'is this it': '2001-07-30',
    'whatever people say i am, that\'s what i\'m not': '2006-01-23',
    'discovery': '2001-03-12',
    'selected ambient works 85-92': '1992-11-09',
    'mezzanine': '1998-04-20',
    'dummy': '1994-08-22',
    'homogenic': '1997-09-22',
    'vespertine': '2001-08-27',
    'remain in light': '1980-10-08',
    'daydream nation': '1988-10-18',
    'siamese dream': '1993-07-27',
    'violator': '1990-03-19',
    'the downward spiral': '1994-03-08',
    'music has the right to children': '1998-04-20',
    'untrue': '2007-11-05',
    'the money store': '2012-04-24',
    'scaring the hoes': '2023-03-24',
    'brat': '2024-06-07',
    'magdalene': '2019-11-08',
    'sos': '2022-12-09',
    'when we all fall asleep, where do we go?': '2019-03-29',
    'melodrama': '2017-06-16',
    'punisher': '2020-06-18',
    'currents': '2015-07-17',
    'bloom': '2012-05-15',
    'depression cherry': '2015-08-28',
    'after hours': '2020-03-20',
    'demon days': '2005-05-23',
    'lateralus': '2001-05-15',
    'aenima': '1996-09-17',
    'ænima': '1996-09-17',
    'songs for the deaf': '2002-08-27',
    'master of puppets': '1986-03-03',
    'toxicity': '2001-09-04',
    'hybrid theory': '2000-10-24',
    'dirt': '1992-09-29',
    'ten': '1991-08-27',
    'dookie': '1994-02-01',
    'the black parade': '2006-10-23',
    'the velvet underground & nico': '1967-03-12',
    'marquee moon': '1977-02-08',
    'psychocandy': '1985-11-18',
    'nowhere': '1990-10-15',
    'long season': '1996-10-25',
    'to see the next part of the dream': '2021-02-23',
  };

  /// Loads previously cached genre tags and original release dates from local disk.
  Future<void> initPersistence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        if (key.startsWith('gtag_')) {
          final cleanKey = key.substring(5);
          final tags = prefs.getStringList(key);
          if (tags != null && tags.isNotEmpty) {
            _cache[cleanKey] = tags;
          }
        } else if (key.startsWith('gdate_')) {
          final cleanKey = key.substring(6);
          final date = prefs.getString(key);
          if (date != null && date.isNotEmpty) {
            _releaseDateCache[cleanKey] = date;
          }
        }
      }
    } catch (_) {}
  }

  void _saveToDisk(String key, List<String> tags) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('gtag_$key', tags);
    } catch (_) {}
  }

  void _saveDateToDisk(String key, String date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gdate_$key', date);
    } catch (_) {}
  }

  /// Retrieves cached original release date for an artist and title, if previously resolved
  /// or available in the curated offline encyclopedia. Guaranteed 0ms return.
  String? getCachedReleaseDate(String artist, String title) {
    final cleanArtist = artist.trim().toLowerCase();
    final cleanTitle = title.trim().toLowerCase();
    final cacheKey = '$cleanArtist:::$cleanTitle';

    if (_releaseDateCache.containsKey(cacheKey) && _releaseDateCache[cacheKey]!.isNotEmpty) {
      return _releaseDateCache[cacheKey];
    }

    if (cleanTitle.isNotEmpty && _curatedReleaseDates.containsKey(cleanTitle)) {
      return _curatedReleaseDates[cleanTitle];
    }

    for (final entry in _curatedReleaseDates.entries) {
      if (cleanTitle.contains(entry.key) || entry.key.contains(cleanTitle)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Synchronously checks in-memory cache, curated canonical albums, and curated artists.
  /// Returns instant genre tags at 0ms without any network request or loading delay.
  List<String> getTagsSync({
    required String artist,
    required String title,
    bool isAlbum = true,
  }) {
    final cleanArtist = artist.trim().toLowerCase();
    final cleanTitle = title.trim().toLowerCase();
    if (cleanArtist.isEmpty && cleanTitle.isEmpty) return const [];

    final cacheKey = '$cleanArtist:::$cleanTitle';
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isNotEmpty) {
      return _cache[cacheKey]!;
    }

    if (cleanTitle.isNotEmpty && _curatedAlbumGenres.containsKey(cleanTitle)) {
      final tags = _curatedAlbumGenres[cleanTitle]!;
      _cache[cacheKey] = tags;
      return tags;
    }

    if (cleanArtist.isNotEmpty && _curatedArtistGenres.containsKey(cleanArtist)) {
      final tags = _curatedArtistGenres[cleanArtist]!;
      _cache[cacheKey] = tags;
      return tags;
    }

    // Substring match in curated album encyclopedia
    for (final entry in _curatedAlbumGenres.entries) {
      if (cleanTitle.contains(entry.key) || entry.key.contains(cleanTitle)) {
        _cache[cacheKey] = entry.value;
        return entry.value;
      }
    }

    // Substring match in curated artist encyclopedia
    for (final entry in _curatedArtistGenres.entries) {
      if (cleanArtist == entry.key || (cleanArtist.length > 4 && cleanArtist.contains(entry.key))) {
        _cache[cacheKey] = entry.value;
        return entry.value;
      }
    }

    return const [];
  }

  /// Synchronously checks curated artist taxonomy at 0ms.
  List<String> getArtistTagsSync(String artist) {
    final clean = artist.trim().toLowerCase();
    if (clean.isEmpty) return const [];
    final cacheKey = 'artist:::$clean';
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isNotEmpty) {
      return _cache[cacheKey]!;
    }
    if (_curatedArtistGenres.containsKey(clean)) {
      final tags = _curatedArtistGenres[clean]!;
      _cache[cacheKey] = tags;
      return tags;
    }
    for (final entry in _curatedArtistGenres.entries) {
      if (clean == entry.key || (clean.length > 4 && clean.contains(entry.key))) {
        _cache[cacheKey] = entry.value;
        return entry.value;
      }
    }
    return const [];
  }

  /// Fires a non-blocking background fetch so tags are pre-warmed ahead of user navigation.
  void prefetchTags({
    required String artist,
    required String title,
    bool isAlbum = true,
  }) {
    final cleanArtist = artist.trim();
    final cleanTitle = title.trim();
    if (cleanArtist.isEmpty && cleanTitle.isEmpty) return;
    final cacheKey = '${cleanArtist.toLowerCase()}:::${cleanTitle.toLowerCase()}';
    if (_cache.containsKey(cacheKey)) return;
    // Launch non-blocking background task
    getTags(artist: cleanArtist, title: cleanTitle, isAlbum: isAlbum);
  }

  // Non-genre community noise tags to filter out
  static const Set<String> _ignoredTags = {
    'albums i own',
    'owned',
    'i own this',
    'seen live',
    'favorites',
    'favourite',
    'favorite albums',
    'favourites',
    'my favorite albums',
    'vinyl',
    'vinyl collection',
    'cd',
    'cassette',
    'spotify',
    'check out',
    'beautiful',
    'masterpiece',
    'classic',
    'all time favorites',
    'all-time favorites',
    '10/10',
    '9/10',
    '8/10',
    'love',
    'awesome',
    'my vinyl collection',
    'buy',
    'wishlist',
    'political',
    'american',
    'british',
    'english',
    'french',
    'german',
    'japanese',
    'canadian',
    'australian',
    'swedish',
    'russian',
    'korean',
    'male vocalist',
    'female vocalist',
    'female vocalists',
    'male vocalists',
    'acoustic',
    'ballad',
    'melancholy',
    'chill',
    'relax',
    'party',
    'summer',
    'driving',
    'workout',
    'alienation',
    'anxious',
    'cynical',
    'sarcastic',
    'mental health',
    'longing',
    'pessimistic',
    'insecure',
    'anti-authoritarian',
    'anticonsumerism',
    'paranoia',
    'dystopian',
    'serious',
    'melancholic',
    'futuristic',
    'atmospheric',
    'dense',
    'falsetto',
    'sad',
    'existential',
    'depressive',
    'poetic',
    'lonely',
    'nihilistic',
    'passionate',
    'introspective',
    'cold',
    'offizielle charts',
    '5+ wochen',
    'uk',
    'britannique',
  };

  GenreTagService({
    http.Client? client,
    this.lastFmApiKey,
    FirebaseFirestore? firestore,
  })  : _client = client ?? http.Client(),
        _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  /// Generates a canonical Firestore document ID from artist and title.
  static String generateDocId(String artist, String title) {
    final cleanA = artist.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_').replaceAll(RegExp(r'_+'), '_');
    final cleanT = title.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_').replaceAll(RegExp(r'_+'), '_');
    return '${cleanA}__${cleanT}';
  }

  /// Generates a canonical Firestore document ID for artist-level taxonomy.
  static String generateArtistDocId(String artist) {
    final cleanA = artist.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_').replaceAll(RegExp(r'_+'), '_');
    return 'artist__$cleanA';
  }

  /// Saves crowd-sourced metadata to Cloud Firestore asynchronously (non-blocking).
  void _saveToFirestore({
    required String docId,
    required String artist,
    required String title,
    List<String>? genres,
    String? releaseDate,
  }) async {
    if (_firestore == null) return;
    try {
      final data = <String, dynamic>{
        'artist': artist,
        if (title.isNotEmpty) 'title': title,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (genres != null && genres.isNotEmpty) {
        data['genres'] = genres;
      }
      if (releaseDate != null && releaseDate.isNotEmpty) {
        data['originalReleaseDate'] = releaseDate;
      }
      await _firestore!.collection('catalog_metadata').doc(docId).set(
        data,
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  String _resolveApiKey() {
    if (lastFmApiKey != null && lastFmApiKey!.trim().isNotEmpty) {
      return lastFmApiKey!.trim();
    }
    const envKey = String.fromEnvironment('LASTFM_API_KEY', defaultValue: '');
    if (envKey.trim().isNotEmpty) {
      return envKey.trim();
    }
    return LastFmConfig.apiKey.trim();
  }

  /// Retrieves granular genre tags for an album/release or song.
  Future<List<String>> getTags({
    required String artist,
    required String title,
    bool isAlbum = true,
  }) async {
    final cleanArtist = artist.trim();
    final cleanTitle = title.trim();
    if (cleanArtist.isEmpty && cleanTitle.isEmpty) return const [];

    final cacheKey = '${cleanArtist.toLowerCase()}:::${cleanTitle.toLowerCase()}';
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isNotEmpty) {
      return _cache[cacheKey]!;
    }

    // 1. Check synchronous curated offline encyclopedia (0ms instant)
    final syncTags = getTagsSync(artist: cleanArtist, title: cleanTitle, isAlbum: isAlbum);
    if (syncTags.isNotEmpty) {
      return syncTags;
    }

    final docId = generateDocId(cleanArtist, cleanTitle);

    // 2. Check Cloud Firestore crowdsourced metadata cache
    if (_firestore != null) {
      try {
        final doc = await _firestore!.collection('catalog_metadata').doc(docId).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final firestoreGenres = (data['genres'] as List?)
              ?.map((e) => e.toString().toUpperCase())
              .where((g) => g.isNotEmpty)
              .toList();
          final firestoreDate = data['originalReleaseDate'] as String?;

          if (firestoreDate != null && firestoreDate.isNotEmpty) {
            _releaseDateCache[cacheKey] = firestoreDate;
            _saveDateToDisk(cacheKey, firestoreDate);
          }

          if (firestoreGenres != null && firestoreGenres.isNotEmpty) {
            final cleanTags = _cleanAndDeduplicate(firestoreGenres).take(5).toList();
            _cache[cacheKey] = cleanTags;
            _saveToDisk(cacheKey, cleanTags);
            return cleanTags;
          }
        }
      } catch (_) {}
    }

    List<String> tags = [];

    // 3. Try Last.fm if an API key is available
    final apiKey = _resolveApiKey();
    if (apiKey.isNotEmpty) {
      tags = await _fetchLastFmTags(
        artist: cleanArtist,
        title: cleanTitle,
        isAlbum: isAlbum,
        apiKey: apiKey,
      );
    }

    // 4. Query MusicBrainz open community taxonomy (free, no auth required)
    if (tags.isEmpty) {
      tags = await _fetchMusicBrainzTags(
        artist: cleanArtist,
        title: cleanTitle,
        isAlbum: isAlbum,
      );
    }

    // 5. Fallback to artist tags if specific release has no tags
    if (tags.isEmpty && cleanArtist.isNotEmpty) {
      tags = await getArtistTags(cleanArtist);
    }

    final cleanTags = _cleanAndDeduplicate(tags).take(5).toList();
    if (cleanTags.isNotEmpty) {
      _cache[cacheKey] = cleanTags;
      _saveToDisk(cacheKey, cleanTags);
      _saveToFirestore(
        docId: docId,
        artist: cleanArtist,
        title: cleanTitle,
        genres: cleanTags,
        releaseDate: _releaseDateCache[cacheKey],
      );
    }
    return cleanTags;
  }

  /// Retrieves granular genre tags for an artist.
  Future<List<String>> getArtistTags(String artist) async {
    final clean = artist.trim();
    if (clean.isEmpty) return const [];

    final cacheKey = 'artist:::${clean.toLowerCase()}';
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isNotEmpty) {
      return _cache[cacheKey]!;
    }

    // 1. Check synchronous curated offline encyclopedia (0ms instant)
    final syncArtistTags = getArtistTagsSync(clean);
    if (syncArtistTags.isNotEmpty) {
      return syncArtistTags;
    }

    final docId = generateArtistDocId(clean);

    // 2. Check Cloud Firestore crowdsourced metadata cache
    if (_firestore != null) {
      try {
        final doc = await _firestore!.collection('catalog_metadata').doc(docId).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final firestoreGenres = (data['genres'] as List?)
              ?.map((e) => e.toString().toUpperCase())
              .where((g) => g.isNotEmpty)
              .toList();
          if (firestoreGenres != null && firestoreGenres.isNotEmpty) {
            final cleanTags = _cleanAndDeduplicate(firestoreGenres).take(5).toList();
            _cache[cacheKey] = cleanTags;
            _saveToDisk(cacheKey, cleanTags);
            return cleanTags;
          }
        }
      } catch (_) {}
    }

    List<String> tags = [];

    final apiKey = _resolveApiKey();
    if (apiKey.isNotEmpty) {
      tags = await _fetchLastFmArtistTags(clean, apiKey: apiKey);
    }

    if (tags.isEmpty) {
      tags = await _fetchMusicBrainzArtistTags(clean);
    }

    final cleanTags = _cleanAndDeduplicate(tags).take(5).toList();
    if (cleanTags.isNotEmpty) {
      _cache[cacheKey] = cleanTags;
      _saveToDisk(cacheKey, cleanTags);
      _saveToFirestore(
        docId: docId,
        artist: clean,
        title: '',
        genres: cleanTags,
      );
    }
    return cleanTags;
  }

  // --------------------------------------------------------------------------
  // Last.fm API Client
  // --------------------------------------------------------------------------

  Future<List<String>> _fetchLastFmTags({
    required String artist,
    required String title,
    required bool isAlbum,
    required String apiKey,
  }) async {
    try {
      final method = isAlbum ? 'album.gettoptags' : 'track.gettoptags';
      final paramName = isAlbum ? 'album' : 'track';

      final uri = Uri.https('ws.audioscrobbler.com', '/2.0/', {
        'method': method,
        'artist': artist,
        paramName: title,
        'api_key': apiKey,
        'format': 'json',
        'autocorrect': '1',
      });

      final response = await _client.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return const [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final topTags = data['toptags'] as Map<String, dynamic>?;
      if (topTags == null) return const [];

      final rawTag = topTags['tag'];
      return _parseLastFmTagList(rawTag);
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> _fetchLastFmArtistTags(String artist, {required String apiKey}) async {
    try {
      final uri = Uri.https('ws.audioscrobbler.com', '/2.0/', {
        'method': 'artist.gettoptags',
        'artist': artist,
        'api_key': apiKey,
        'format': 'json',
        'autocorrect': '1',
      });

      final response = await _client.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return const [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final topTags = data['toptags'] as Map<String, dynamic>?;
      if (topTags == null) return const [];

      final rawTag = topTags['tag'];
      return _parseLastFmTagList(rawTag);
    } catch (_) {
      return const [];
    }
  }

  List<String> _parseLastFmTagList(dynamic rawTag) {
    if (rawTag is List) {
      final items = List<Map<String, dynamic>>.from(
        rawTag.whereType<Map<String, dynamic>>(),
      );
      items.sort((a, b) {
        final countA = int.tryParse(a['count']?.toString() ?? '0') ?? 0;
        final countB = int.tryParse(b['count']?.toString() ?? '0') ?? 0;
        return countB.compareTo(countA);
      });
      return items
          .map((t) => t['name']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (rawTag is Map && rawTag['name'] != null) {
      return [rawTag['name'].toString()];
    }
    return const [];
  }

  // --------------------------------------------------------------------------
  // MusicBrainz API Client (Open & Free Fallback)
  // --------------------------------------------------------------------------

  Future<List<String>> _fetchMusicBrainzTags({
    required String artist,
    required String title,
    required bool isAlbum,
  }) async {
    try {
      // MusicBrainz release-group query for albums/EPs
      final cleanTitle = _sanitizeForQuery(title);
      final cleanArtist = _sanitizeForQuery(artist);
      final query = 'releasegroup:$cleanTitle AND artist:$cleanArtist';

      final uri = Uri.https('musicbrainz.org', '/ws/2/release-group', {
        'query': query,
        'fmt': 'json',
      });

      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'GroovdMusicApp/1.0.0 (contact@groovd.fm)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) return const [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final groups = data['release-groups'] as List?;
      if (groups == null || groups.isEmpty) return const [];

      final first = groups.first as Map<String, dynamic>;
      final firstReleaseDate = first['first-release-date'] as String?;
      if (firstReleaseDate != null && firstReleaseDate.trim().isNotEmpty) {
        _releaseDateCache['${cleanArtist.toLowerCase()}:::${cleanTitle.toLowerCase()}'] = firstReleaseDate.trim();
      }

      final tags = first['tags'] as List?;
      if (tags == null) return const [];

      final items = List<Map<String, dynamic>>.from(
        tags.whereType<Map<String, dynamic>>(),
      );
      items.sort((a, b) {
        final countA = (a['count'] as num?)?.toInt() ?? 0;
        final countB = (b['count'] as num?)?.toInt() ?? 0;
        return countB.compareTo(countA);
      });

      return items
          .map((t) => t['name']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Retrieves the accurate encyclopedic original release date from MusicBrainz release-group.
  Future<String?> getOriginalReleaseDate({
    required String artist,
    required String title,
  }) async {
    final cleanArtist = artist.trim();
    final cleanTitle = title.trim();
    if (cleanArtist.isEmpty && cleanTitle.isEmpty) return null;

    final cacheKey = '${cleanArtist.toLowerCase()}:::${cleanTitle.toLowerCase()}';
    if (_releaseDateCache.containsKey(cacheKey) && _releaseDateCache[cacheKey]!.isNotEmpty) {
      return _releaseDateCache[cacheKey];
    }

    final cached = getCachedReleaseDate(cleanArtist, cleanTitle);
    if (cached != null && cached.isNotEmpty) {
      _releaseDateCache[cacheKey] = cached;
      return cached;
    }

    final docId = generateDocId(cleanArtist, cleanTitle);

    // 2. Check Cloud Firestore crowdsourced metadata cache
    if (_firestore != null) {
      try {
        final doc = await _firestore!.collection('catalog_metadata').doc(docId).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final firestoreDate = data['originalReleaseDate'] as String?;
          if (firestoreDate != null && firestoreDate.isNotEmpty) {
            _releaseDateCache[cacheKey] = firestoreDate;
            _saveDateToDisk(cacheKey, firestoreDate);
            return firestoreDate;
          }
        }
      } catch (_) {}
    }

    try {
      final cleanTitleSanitized = _sanitizeForQuery(cleanTitle);
      final cleanArtistSanitized = _sanitizeForQuery(cleanArtist);
      final query = 'releasegroup:$cleanTitleSanitized AND artist:$cleanArtistSanitized';

      final uri = Uri.https('musicbrainz.org', '/ws/2/release-group', {
        'query': query,
        'fmt': 'json',
      });

      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'GroovdMusicApp/1.0.0 (contact@groovd.fm)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final groups = data['release-groups'] as List?;
      if (groups == null || groups.isEmpty) return null;

      final first = groups.first as Map<String, dynamic>;
      final date = first['first-release-date'] as String?;
      if (date != null && date.trim().isNotEmpty) {
        final cleanDate = date.trim();
        _releaseDateCache[cacheKey] = cleanDate;
        _saveDateToDisk(cacheKey, cleanDate);
        _saveToFirestore(
          docId: docId,
          artist: cleanArtist,
          title: cleanTitle,
          releaseDate: cleanDate,
        );
        return cleanDate;
      }
    } catch (_) {}
    return null;
  }

  Future<List<String>> _fetchMusicBrainzArtistTags(String artist) async {
    try {
      final cleanArtist = _sanitizeForQuery(artist);
      final uri = Uri.https('musicbrainz.org', '/ws/2/artist', {
        'query': 'artist:$cleanArtist',
        'fmt': 'json',
      });

      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'GroovdMusicApp/1.0.0 (contact@groovd.fm)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) return const [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final artists = data['artists'] as List?;
      if (artists == null || artists.isEmpty) return const [];

      final first = artists.first as Map<String, dynamic>;
      final tags = first['tags'] as List?;
      if (tags == null) return const [];

      final items = List<Map<String, dynamic>>.from(
        tags.whereType<Map<String, dynamic>>(),
      );
      items.sort((a, b) {
        final countA = (a['count'] as num?)?.toInt() ?? 0;
        final countB = (b['count'] as num?)?.toInt() ?? 0;
        return countB.compareTo(countA);
      });

      return items
          .map((t) => t['name']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  String _sanitizeForQuery(String input) {
    // Strip punctuation that could break Lucene queries
    return input.replaceAll(RegExp(r'[\/\\:*\?"<>|~^!\[\]{}+-]'), ' ').trim();
  }

  List<String> _cleanAndDeduplicate(List<String> raw) {
    final seen = <String>{};
    final result = <String>[];

    for (final tag in raw) {
      final lower = tag.trim().toLowerCase();
      if (lower.isEmpty || lower.length > 28 || lower.length < 2) continue;
      if (RegExp(r'^\d+$').hasMatch(lower) || RegExp(r'^\d+s$').hasMatch(lower)) continue;
      if (_ignoredTags.contains(lower)) continue;
      if (lower.contains('discogs') || lower.contains('favorite') || lower.contains('review')) continue;

      final normalized = _formatGenre(lower);
      if (seen.add(normalized.toUpperCase())) {
        result.add(normalized.toUpperCase());
      }
    }

    return result;
  }

  String _formatGenre(String s) {
    // Normalization rules for clean visual appearance
    final normalized = s.replaceAll('_', ' ').replaceAll('-', ' ').trim();
    if (normalized == 'r&b' || normalized == 'rnb') return 'R&B';
    if (normalized == 'hip hop' || normalized == 'hiphop') return 'HIP-HOP';
    if (normalized == 'post punk') return 'POST-PUNK';
    if (normalized == 'art pop') return 'ART POP';
    if (normalized == 'art rock') return 'ART ROCK';
    if (normalized == 'indie rock') return 'INDIE ROCK';
    if (normalized == 'synth pop' || normalized == 'synthpop') return 'SYNTH-POP';
    if (normalized == 'dream pop') return 'DREAM POP';
    if (normalized == 'neo soul') return 'NEO-SOUL';
    if (normalized == 'french house') return 'FRENCH HOUSE';
    return normalized.toUpperCase();
  }
}
