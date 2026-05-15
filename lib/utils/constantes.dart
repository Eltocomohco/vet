import 'package:flutter/material.dart';

// ==================== COLORES PRINCIPALES ====================
const Color colorPrimario = Color(0xFF2E7D32);
const Color colorPrimarioClaro = Color(0xFF4CAF50);
const Color colorPrimarioOscuro = Color(0xFF1B5E20);
const Color colorAcento = Color(0xFF66BB6A);

// ==================== COLORES DE ESTADO ====================
const Color colorEstadoPendiente = Color(0xFFFFA726);
const Color colorEstadoConfirmada = Color(0xFF66BB6A);
const Color colorEstadoEnProgreso = Color(0xFF42A5F5);
const Color colorEstadoCompletada = Color(0xFF2E7D32);
const Color colorEstadoCancelada = Color(0xFFEF5350);
const Color colorEstadoNoShow = Color(0xFF78909C);

// ==================== COLORES DE FONDO ====================
const Color colorFondo = Color(0xFFF5F7FA);
const Color colorFondoClaro = Color(0xFFFFFFFF);
const Color colorFondoOscuro = Color(0xFFE8EDF2);

// ==================== COLORES DE TEXTO ====================
const Color colorTextoPrimario = Color(0xFF212121);
const Color colorTextoSecundario = Color(0xFF616161);
const Color colorTextoHint = Color(0xFF9E9E9E);
const Color colorTextoInverso = Color(0xFFFFFFFF);

// ==================== COLORES DE ERROR / EXITO ====================
const Color colorError = Color(0xFFD32F2F);
const Color colorErrorClaro = Color(0xFFFFEBEE);
const Color colorExito = Color(0xFF388E3C);
const Color colorExitoClaro = Color(0xFFE8F5E9);
const Color colorAdvertencia = Color(0xFFF57C00);
const Color colorAdvertenciaClaro = Color(0xFFFFF3E0);
const Color colorInformacion = Color(0xFF1976D2);
const Color colorInformacionClaro = Color(0xFFE3F2FD);

// ==================== COLORES DE ESPECIES ====================
const Color colorEspeciePerro = Color(0xFF8D6E63);
const Color colorEspecieGato = Color(0xFFFFB74D);
const Color colorEspecieAve = Color(0xFF4FC3F7);
const Color colorEspecieConejo = Color(0xFFCE93D8);
const Color colorEspecieReptil = Color(0xFF81C784);
const Color colorEspecieOtro = Color(0xFFB0BEC5);

// ==================== ESPACIADOS ====================
const double espacioMicro = 4.0;
const double espacioPequeno = 8.0;
const double espacioMedio = 16.0;
const double espacioGrande = 24.0;
const double espacioExtraGrande = 32.0;
const double espacioXXL = 48.0;

// ==================== BORDES ====================
const double radioBordePequeno = 6.0;
const double radioBordeMedio = 10.0;
const double radioBordeGrande = 16.0;
const double radioBordeCircular = 50.0;

// ==================== ELEVACIONES ====================
const double elevacionSombra = 4.0;
const double elevacionCard = 2.0;
const double elevacionDialogo = 8.0;

// ==================== DURACIONES ====================
const Duration duracionAnimacionRapida = Duration(milliseconds: 150);
const Duration duracionAnimacionNormal = Duration(milliseconds: 300);
const Duration duracionAnimacionLenta = Duration(milliseconds: 500);

// ==================== TAMANOS DE TEXTO ====================
const double textoDisplay = 28.0;
const double textoTitulo = 22.0;
const double textoSubtitulo = 18.0;
const double textoCuerpo = 14.0;
const double textoCuerpoGrande = 16.0;
const double textoPequeno = 12.0;
const double textoMuyPequeno = 10.0;

// ==================== ESTILOS DE TEXTO ====================
TextStyle estiloDisplay = const TextStyle(
  fontSize: textoDisplay,
  fontWeight: FontWeight.bold,
  color: colorTextoPrimario,
);

TextStyle estiloTitulo = const TextStyle(
  fontSize: textoTitulo,
  fontWeight: FontWeight.bold,
  color: colorTextoPrimario,
);

TextStyle estiloSubtitulo = const TextStyle(
  fontSize: textoSubtitulo,
  fontWeight: FontWeight.w600,
  color: colorTextoPrimario,
);

TextStyle estiloCuerpo = const TextStyle(
  fontSize: textoCuerpo,
  fontWeight: FontWeight.normal,
  color: colorTextoPrimario,
);

TextStyle estiloCuerpoGrande = const TextStyle(
  fontSize: textoCuerpoGrande,
  fontWeight: FontWeight.normal,
  color: colorTextoPrimario,
);

TextStyle estiloCuerpoSecundario = const TextStyle(
  fontSize: textoCuerpo,
  fontWeight: FontWeight.normal,
  color: colorTextoSecundario,
);

TextStyle estiloPequeno = const TextStyle(
  fontSize: textoPequeno,
  fontWeight: FontWeight.normal,
  color: colorTextoSecundario,
);

TextStyle estiloMuyPequeno = const TextStyle(
  fontSize: textoMuyPequeno,
  fontWeight: FontWeight.normal,
  color: colorTextoHint,
);

TextStyle estiloBotonPrimario = const TextStyle(
  fontSize: textoCuerpoGrande,
  fontWeight: FontWeight.w600,
  color: colorTextoInverso,
);

TextStyle estiloBotonSecundario = const TextStyle(
  fontSize: textoCuerpoGrande,
  fontWeight: FontWeight.w600,
  color: colorPrimario,
);

// ==================== ENUMS ====================
enum MotivoCita {
  consultaGeneral,
  vacunacion,
  desparasitacion,
  cirugia,
  urgencia,
  revision,
  peluqueria,
  analisis,
  otros;

  String get displayName {
    switch (this) {
      case MotivoCita.consultaGeneral:
        return 'Consulta General';
      case MotivoCita.vacunacion:
        return 'Vacunacion';
      case MotivoCita.desparasitacion:
        return 'Desparasitacion';
      case MotivoCita.cirugia:
        return 'Cirugia';
      case MotivoCita.urgencia:
        return 'Urgencia';
      case MotivoCita.revision:
        return 'Revision';
      case MotivoCita.peluqueria:
        return 'Peluqueria';
      case MotivoCita.analisis:
        return 'Analisis';
      case MotivoCita.otros:
        return 'Otros';
    }
  }
}

enum EstadoCita {
  pendiente,
  confirmada,
  enProgreso,
  completada,
  cancelada,
  noShow;

  String get displayName {
    switch (this) {
      case EstadoCita.pendiente:
        return 'Pendiente';
      case EstadoCita.confirmada:
        return 'Confirmada';
      case EstadoCita.enProgreso:
        return 'En Progreso';
      case EstadoCita.completada:
        return 'Completada';
      case EstadoCita.cancelada:
        return 'Cancelada';
      case EstadoCita.noShow:
        return 'No Asistio';
    }
  }
}

// ==================== MAPAS DE COLORES POR ESTADO ====================
const Map<String, Color> coloresEstado = {
  'pendiente': colorEstadoPendiente,
  'confirmada': colorEstadoConfirmada,
  'enProgreso': colorEstadoEnProgreso,
  'completada': colorEstadoCompletada,
  'cancelada': colorEstadoCancelada,
  'noShow': colorEstadoNoShow,
};

const Map<String, Color> coloresEstadoFondo = {
  'pendiente': colorAdvertenciaClaro,
  'confirmada': colorExitoClaro,
  'enProgreso': colorInformacionClaro,
  'completada': colorExitoClaro,
  'cancelada': colorErrorClaro,
  'noShow': Color(0xFFECEFF1),
};

// ==================== LISTA DE ESPECIES ====================
const List<String> listaEspecies = [
  'Perro',
  'Gato',
  'Ave',
  'Conejo',
  'Roedor',
  'Reptil',
  'Pez',
  'Huron',
  'Otro',
];

// ==================== MAPA DE COLORES POR ESPECIE ====================
const Map<String, Color> coloresEspecie = {
  'Perro': colorEspeciePerro,
  'Gato': colorEspecieGato,
  'Ave': colorEspecieAve,
  'Conejo': colorEspecieConejo,
  'Roedor': Color(0xFFBCAAA4),
  'Reptil': colorEspecieReptil,
  'Pez': Color(0xFF5C6BC0),
  'Huron': Color(0xFFA1887F),
  'Otro': colorEspecieOtro,
};

// ==================== LISTA DE RAZAS COMUNES ====================
const Map<String, List<String>> razasPorEspecie = {
  'Perro': [
    'Mestizo',
    'Labrador',
    'Pastor Aleman',
    'Bulldog Frances',
    'Golden Retriever',
    'Chihuahua',
    'Beagle',
    'Boxer',
    'Poodle',
    'Yorkshire Terrier',
    'Rottweiler',
    'Husky Siberiano',
    'Dalmatian',
    'Shih Tzu',
    'Otro',
  ],
  'Gato': [
    'Mestizo',
    'Siames',
    'Persa',
    'Maine Coon',
    'Bengali',
    'Ragdoll',
    'Esfinje',
    'Britanico de Pelo Corto',
    'Otro',
  ],
  'Ave': [
    'Canario',
    'Periquito',
    'Cacatua',
    'Agaporni',
    'Ninfa',
    'Guacamayo',
    'Otro',
  ],
  'Conejo': [
    'Enano',
    'Belier',
    'Cabeza de Leon',
    'Rex',
    'Angora',
    'Otro',
  ],
  'Roedor': [
    'Hamster',
    'Cobaya',
    'Rata',
    'Raton',
    'Chinchilla',
    'Otro',
  ],
  'Reptil': [
    'Tortuga',
    'Iguana',
    'Camaleon',
    'Serpiente',
    'Gecko',
    'Dragon Barbudo',
    'Otro',
  ],
  'Pez': [
    'Goldfish',
    'Betta',
    'Guppy',
    'Tetra',
    'Ciclido',
    'Otro',
  ],
  'Huron': [
    'Estandar',
    'Angora',
    'Otro',
  ],
  'Otro': [
    'Otro',
  ],
};

// ==================== LISTA DE SEXOS ====================
const List<String> listaSexos = [
  'Macho',
  'Hembra',
  'Desconocido',
];

// ==================== LISTA DE TIPOS DE VACUNA ====================
const List<String> listaTiposVacuna = [
  'Rabia',
  'Moquillo',
  'Parvovirus',
  'Leptospirosis',
  'Hepatitis',
  'Trivalente',
  'Tetravalente',
  'Pentavalente',
  'Bordetella',
  'Leucemia Felina',
  'Peritonitis Infecciosa',
  'Otra',
];

// ==================== ROLES DE USUARIO ====================
const String rolAdmin = 'admin';
const String rolVeterinario = 'veterinario';
const String rolRecepcionista = 'recepcionista';

const List<String> listaRoles = [
  rolAdmin,
  rolVeterinario,
  rolRecepcionista,
];

// ==================== PLANES DE SUSCRIPCION ====================
// Precios ajustados para A Coruna - mas competitivos que Madrid/Barcelona
const String planBasico = 'basico';
const String planProfesional = 'profesional';
const String planPremium = 'premium';

const Map<String, String> nombresPlanes = {
  planBasico: 'Basico',
  planProfesional: 'Profesional',
  planPremium: 'Premium',
};

const Map<String, double> preciosPlanes = {
  planBasico: 15.0,       // 1 veterinario, 200 mascotas
  planProfesional: 29.0,  // 3 veterinarios, ilimitado
  planPremium: 59.0,      // Multi-sede, soporte prioritario
};

const int limiteMascotasBasico = 200;
const int limiteVeterinariosBasico = 1;
const int limiteVeterinariosPro = 3;

// ==================== TAMANOS DE PANTALLA ====================
const double anchoPantallaMovil = 600;
const double anchoPantallaTablet = 1024;

// ==================== CONSTANTES DE PAGINACION ====================
const int limitePaginacion = 20;

// ==================== CONSTANTES DE FIREBASE ====================
const String coleccionClinicas = 'clinicas';
const String coleccionMascotas = 'mascotas';
const String coleccionCitas = 'citas';
const String coleccionUsuarios = 'usuarios';
const String coleccionVacunas = 'vacunas';
const String subcoleccionVacunasMascota = 'vacunas';
const String subcoleccionHistorial = 'historial';

// ==================== MENSAJES DE ERROR COMUNES ====================
const String mensajeErrorGenerico = 'Ha ocurrido un error. Intente nuevamente.';
const String mensajeErrorConexion = 'Error de conexion. Verifique su internet.';
const String mensajeErrorPermiso = 'No tiene permisos para realizar esta accion.';
const String mensajeErrorDatos = 'Error al procesar los datos.';
const String mensajeErrorNoEncontrado = 'No se encontro el recurso solicitado.';

// ==================== ALIASES EN INGLES (compatibilidad con UI generada) ====================
const Color kPrimary = colorPrimario;
const Color kPrimaryLight = colorPrimarioClaro;
const Color kPrimaryDark = colorPrimarioOscuro;
const Color kAccent = colorAcento;
const Color kBackground = colorFondo;
const Color kSurface = colorFondoClaro;
const Color kError = colorError;
const Color kTextPrimary = colorTextoPrimario;
const Color kTextSecondary = colorTextoSecundario;
const Color kStatusPendiente = colorEstadoPendiente;
const Color kStatusConfirmada = colorEstadoConfirmada;
const Color kStatusCancelada = colorEstadoCancelada;
const Color kStatusCompletada = colorEstadoCompletada;
const Color kStatusNoShow = colorEstadoNoShow;
