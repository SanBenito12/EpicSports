# EpicSports

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white) ![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white) ![Push Notifications](https://img.shields.io/badge/Push%20Notifications-informational?style=flat-square&logo=appveyor) ![Realtime Markers](https://img.shields.io/badge/Realtime%20Markers-informational?style=flat-square&logo=clockify) ![Sport Radar API](https://img.shields.io/badge/Sport%20Radar%20API-informational?style=flat-square&logo=sportradar)

APP DEPORTIVA HECHA EN FLUTTER QUE MUESTRA PARTIDOS CON MARCADORES EN VIVO DE MLB USANDO API DE SPORT RADAR


## Introducción

EpicSports es una aplicación móvil para Android desarrollada en Flutter, diseñada para los fanáticos del béisbol que desean mantenerse al día con la Major League Baseball (MLB). La aplicación resuelve el problema de acceder a información deportiva en tiempo real de manera rápida y eficiente, ofreciendo marcadores en vivo, calendarios de partidos y notificaciones personalizadas directamente en sus dispositivos móviles.

El principal objetivo de EpicSports es brindar una experiencia de usuario inmersiva y actualizada para los seguidores de la MLB.  En un mundo donde la información deportiva es abundante pero a menudo dispersa y desorganizada, EpicSports centraliza los datos más relevantes, utilizando la API de Sport Radar para asegurar la precisión y la puntualidad de la información mostrada.

EpicSports es ideal para:

*   **Aficionados casuales:** Que buscan una manera sencilla de seguir los resultados de sus equipos favoritos.
*   **Fanáticos acérrimos:** Que desean acceso instantáneo a estadísticas detalladas y actualizaciones en vivo durante los partidos.
*   **Personas ocupadas:** Que necesitan recibir notificaciones push sobre momentos clave de los partidos sin tener que estar constantemente revisando la aplicación.

En resumen, EpicSports se esfuerza por ser la aplicación de referencia para los aficionados de la MLB, ofreciendo una combinación de información en tiempo real, una interfaz de usuario intuitiva y notificaciones personalizadas para mejorar la experiencia general de seguimiento del béisbol.

## Características

EpicSports ofrece una experiencia completa para los fanáticos del béisbol, centrada en proporcionar información en vivo y funcionalidades convenientes. A continuación, se detallan las características clave:

*   **Notificaciones Push Personalizadas:**
    *   Recibe alertas instantáneas sobre momentos cruciales de los partidos de la MLB, como el inicio y fin de los juegos, cambios de marcador significativos (home runs, carreras anotadas), y otras actualizaciones relevantes. Estas notificaciones son totalmente personalizables; los usuarios pueden elegir recibir alertas solo para sus equipos favoritos o para tipos específicos de eventos dentro de un juego.
    *   La implementación de notificaciones push se basa en Firebase Cloud Messaging (FCM), asegurando una entrega confiable y eficiente de las alertas.

*   **Marcadores en Tiempo Real:**
    *   Sigue la acción en vivo con actualizaciones de marcadores en tiempo real para todos los partidos de la MLB. La aplicación muestra información detallada, incluyendo la alineación del equipo, el conteo de bolas y strikes, el estado de las bases, y las estadísticas clave de los jugadores en tiempo real.
    *   Los marcadores se actualizan automáticamente a través de la API de Sport Radar, lo que garantiza que los usuarios siempre tengan la información más precisa y actualizada disponible.

*   **Calendario de Partidos del Día:**
    *   Consulta fácilmente el calendario completo de partidos del día, con horarios de inicio y detalles de transmisión (si están disponibles). La aplicación organiza los partidos por hora, permitiendo a los usuarios planificar su visualización de juegos de manera eficiente.
    *   La vista de calendario es interactiva, permitiendo a los usuarios tocar cualquier partido para ver detalles adicionales, incluyendo enfrentamientos directos, récords de temporada, y estadísticas relevantes del equipo.

*   **Integración con Sport Radar API:**
    *   La aplicación se integra perfectamente con la API de Sport Radar para obtener datos precisos y actualizados sobre los partidos de la MLB. Esto asegura que la información mostrada a los usuarios sea confiable y provenga de una fuente de datos oficial.

*   **Interfaz de Usuario Intuitiva:**
    *   Diseñada con Flutter, la aplicación ofrece una interfaz de usuario fluida y responsiva que es fácil de navegar tanto en teléfonos como en tabletas. La interfaz está optimizada para una experiencia de usuario agradable, con elementos visuales claros y una disposición lógica de la información.

## Instalación

Para instalar y ejecutar EpicSports en tu entorno local, sigue estos pasos:

### Prerrequisitos

Antes de comenzar, asegúrate de tener instalados los siguientes requisitos:

*   **Flutter SDK:** Asegúrate de tener Flutter instalado y configurado en tu sistema. Puedes descargar la última versión desde el [sitio web oficial de Flutter](https://flutter.dev/docs/get-started/install). Sigue las instrucciones específicas para tu sistema operativo.
*   **Android SDK:** Necesitarás el Android SDK para emular o ejecutar la aplicación en un dispositivo Android. Flutter usa el Android SDK para compilar la aplicación para Android. Asegúrate de que la variable de entorno `ANDROID_HOME` esté configurada correctamente.
*   **IDE (Opcional):** Android Studio o VS Code con el plugin de Flutter son recomendables para el desarrollo. Esto te proporcionará herramientas de depuración y autocompletado.
*   **Git:** Necesitas Git para clonar el repositorio del proyecto.

### Pasos de Instalación

1.  **Clonar el Repositorio**

    Abre tu terminal y navega hasta el directorio donde deseas clonar el proyecto EpicSports. Ejecuta el siguiente comando:

    ```bash
    git clone [URL_DEL_REPOSITORIO]
    cd EpicSports
    ```

    Reemplaza `[URL_DEL_REPOSITORIO]` con la URL real del repositorio de EpicSports.

2.  **Instalar Dependencias de Flutter**

    Una vez que hayas clonado el repositorio, navega hasta el directorio del proyecto (si no lo has hecho ya) y ejecuta el siguiente comando para instalar todas las dependencias necesarias:

    ```bash
    flutter pub get
    ```

    Este comando descargará todas las dependencias especificadas en el archivo `pubspec.yaml`.

3.  **Configuración de la API de Sport Radar**

    Para obtener los marcadores en vivo de MLB, EpicSports utiliza la API de Sport Radar. Necesitarás obtener una clave de API y configurarla en la aplicación.

    *   Regístrate en [Sport Radar Developer Portal](https://developer.sportradar.com/).
    *   Obtén una clave de API para el servicio de MLB.
    *   Abre el archivo `lib/config.dart` (o similar, dependiendo de la estructura del proyecto) y actualiza la variable `apiKey` con tu clave de API:

        ```dart
        const String apiKey = 'YOUR_SPORT_RADAR_API_KEY';
        ```

    **Nota:** Es altamente recomendable no subir la API key directamente al repositorio. Para mayor seguridad, puedes usar variables de entorno o un archivo `.env`.

4.  **Ejecutar la Aplicación**

    Con todas las dependencias instaladas y la clave de API configurada, puedes ejecutar la aplicación en un emulador o en un dispositivo físico. Asegúrate de que tu emulador esté en funcionamiento o que tu dispositivo esté conectado y reconocido por Flutter. Luego, ejecuta el siguiente comando:

    ```bash
    flutter run
    ```

    Flutter compilará y ejecutará la aplicación en el dispositivo o emulador seleccionado.

### Solución de Problemas Comunes

*   **Problemas con las Dependencias:** Si encuentras problemas durante la instalación de las dependencias, asegúrate de tener la última versión de Flutter y de que tu configuración de Android SDK sea correcta. Intenta ejecutar `flutter doctor` para identificar posibles problemas.
*   **Problemas con la API Key:** Verifica que la API Key sea correcta y que tenga permisos para acceder a los datos de MLB. También verifica que el formato de la API Key sea el correcto.
*   **Problemas de Compilación:** Si la aplicación no se compila, revisa los mensajes de error en la terminal. Asegúrate de que no haya errores de sintaxis en tu código y de que todas las dependencias estén instaladas correctamente.

## Uso

## Uso

Una vez que la aplicación EpicSports esté instalada en tu dispositivo Android, puedes comenzar a disfrutar de todas sus funcionalidades. Aquí te mostramos cómo:

**1. Ejecutando la Aplicación:**

*   Busca el icono de EpicSports en tu pantalla de inicio o cajón de aplicaciones y tócalo para iniciarla.

**2. Navegación Principal:**

*   **Partidos del Día:** Al abrir la aplicación, la pantalla principal mostrará una lista de los partidos de MLB programados para el día actual. Cada partido mostrará los equipos que se enfrentan.

**3. Marcadores en Tiempo Real:**

*   Para ver los marcadores en tiempo real de un partido específico, simplemente toca el partido de la lista. Se abrirá una pantalla con la información detallada del partido, incluyendo:
    *   Anotaciones por entrada
    *   Estadísticas clave del juego
    *   Información sobre los jugadores

**4. Notificaciones Push:**

*   EpicSports te enviará notificaciones push para mantenerte al tanto de los momentos importantes de los partidos:
    *   **Inicio del partido:** Recibirás una notificación cuando un partido que sigues esté a punto de comenzar.
    *   **Actualizaciones de marcador:** Recibirás notificaciones cuando haya cambios significativos en el marcador, como carreras anotadas.
    *   **Finalización del partido:** Recibirás una notificación cuando un partido haya terminado, con el resultado final.

*Para asegurarte de recibir las notificaciones, verifica que las notificaciones estén habilitadas para la aplicación EpicSports en la configuración de tu dispositivo Android (Ajustes -> Notificaciones -> EpicSports).* 

**Ejemplo de Interacción:**

1.  Abres la aplicación EpicSports.
2.  Ves una lista de partidos de MLB programados para hoy.
3.  Seleccionas el partido entre Los Angeles Dodgers y San Francisco Giants.
4.  Observas el marcador en tiempo real y las estadísticas del partido.
5.  Recibes una notificación push cuando Mookie Betts conecta un jonrón en la parte baja de la quinta entrada.

**Nota:** La aplicación utiliza la API de Sport Radar para obtener los datos de los partidos y los marcadores en tiempo real. Asegúrate de tener una conexión a Internet estable para recibir la información más actualizada.

## Tecnologías

EpicSports está construido utilizando las siguientes tecnologías clave:

*   **Flutter:** El framework de desarrollo de UI de Google es el corazón de nuestra aplicación. Elegimos Flutter por su capacidad para crear aplicaciones de alto rendimiento, visualmente atractivas y con una base de código única para iOS y Android. Su sistema de widgets rico y personalizable nos permite ofrecer una experiencia de usuario consistente y fluida en ambas plataformas. Además, el desarrollo rápido y la recarga en caliente de Flutter aceleraron significativamente nuestro ciclo de desarrollo.

*   **Dart:** El lenguaje de programación utilizado por Flutter. Dart proporciona un rendimiento excelente con una sintaxis limpia y fácil de aprender. Su soporte para programación asíncrona es crucial para manejar las actualizaciones de datos en tiempo real de la API de Sport Radar.

*   **SportRadar API:** Esta API proporciona los datos en vivo de los partidos de la MLB. Su elección se basa en la necesidad de una fuente de datos confiable y completa para marcadores en tiempo real, estadísticas y otra información relevante para los partidos.

*   **Firebase Cloud Messaging (FCM):** Utilizamos FCM para implementar las notificaciones push. Esto permite a los usuarios recibir alertas instantáneas sobre el inicio de los partidos, actualizaciones de puntaje y otros eventos importantes.

La combinación de estas tecnologías nos permite ofrecer una aplicación deportiva robusta, escalable y fácil de usar para los fanáticos de la MLB.

## Notificaciones Push

### Notificaciones Push

Esta aplicación `EpicSports` utiliza notificaciones push para mantener a los usuarios informados sobre los momentos clave de los partidos de la MLB. Las notificaciones push se implementan utilizando Firebase Cloud Messaging (FCM) para la entrega confiable y eficiente de mensajes a dispositivos Android.

**Funcionalidades Clave:**

*   **Alertas de Inicio de Partido:** Recibe una notificación cuando un partido de tu interés está a punto de comenzar. Esto asegura que no te pierdas el inicio de la acción.
*   **Actualizaciones de Marcador en Tiempo Real:** Recibe notificaciones instantáneas cada vez que hay un cambio en el marcador. Esto incluye carreras, hits y errores importantes. Los usuarios pueden configurar qué tipo de eventos activan las notificaciones.
*   **Alertas de Fin de Partido:** Se envía una notificación al finalizar el partido con el resultado final. Así, siempre estarás al tanto del desenlace de cada encuentro.
*   **Notificaciones Personalizables:**  Los usuarios pueden personalizar los equipos de la MLB de los que desean recibir notificaciones, asegurando que solo reciban alertas relevantes para sus intereses.
*   **Programación de Notificaciones:** La app permite programar notificaciones para partidos futuros.  El usuario puede establecer recordatorios para no perderse ningún encuentro.

**Implementación Técnica:**

1.  **Firebase Cloud Messaging (FCM):** Utilizamos FCM como nuestro proveedor de servicios de notificaciones push. Esto requiere la configuración de un proyecto de Firebase y la integración del SDK de Firebase en la aplicación Flutter.

2.  **Tokens de Dispositivo:** Cada instancia de la aplicación registra un token de dispositivo único con FCM. Este token se utiliza para dirigir notificaciones específicamente a ese dispositivo.

3.  **Backend de Notificaciones:** Un backend (no incluido en este repositorio, pero podría ser implementado con Node.js o Python) gestiona el envío de notificaciones a través de la API de FCM. Este backend recibe eventos de la API de Sport Radar y los traduce en notificaciones push.

4.  **Manejo de Notificaciones en Flutter:** La aplicación Flutter maneja las notificaciones recibidas en segundo plano y en primer plano. Cuando se recibe una notificación, se muestra una alerta en el dispositivo del usuario.

**Configuración (Requiere Backend):**

Para habilitar completamente las notificaciones push, necesitarás un backend configurado para enviar mensajes a FCM.  Aquí están los pasos generales:

   1.  **Crear un Proyecto de Firebase:** Ve a la consola de Firebase y crea un nuevo proyecto.

   2.  **Configurar FCM:** Habilita FCM para tu proyecto de Firebase.

   3.  **Obtener las Credenciales:** Obtén las credenciales de tu proyecto de Firebase (clave de servidor) que se utilizarán en tu backend.

   4.  **Implementar el Backend:**  Crea un backend que escuche los eventos de Sport Radar y envíe notificaciones a FCM usando las credenciales obtenidas. Un ejemplo de código para enviar una notificación básica en Node.js (usando el paquete `firebase-admin`) sería:

```javascript
const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccountKey),
});

const message = {
  notification: {
    title: '¡Gol!',
    body: 'El equipo local acaba de anotar.',
  },
  token: deviceToken,
};

admin.messaging().send(message)
  .then((response) => {
    console.log('Successfully sent message:', response);
  })
  .catch((error) => {
    console.log('Error sending message:', error);
  });
```

   5.  **Configurar la Aplicación Flutter:**  Asegúrate de que la aplicación Flutter esté correctamente configurada para recibir notificaciones de FCM. Esto implica agregar el SDK de Firebase a tu proyecto Flutter y configurar el `FirebaseMessaging`.

**Nota:** Esta sección asume que ya tienes un conocimiento básico de Firebase Cloud Messaging y su integración con aplicaciones Flutter. Consulta la documentación oficial de Firebase para obtener información más detallada.

## Marcadores en tiempo real

La funcionalidad de marcadores en tiempo real es el núcleo de EpicSports. Permite a los usuarios seguir la acción de los partidos de la MLB en vivo, sin demoras significativas. Esta sección describe cómo se implementa esta característica y los detalles técnicos relevantes.

**Fuente de Datos:**

Los marcadores en tiempo real se obtienen a través de la API de SportRadar.  Se ha implementado una conexión persistente con la API para garantizar que los datos se actualicen de manera continua. Se utilizan suscripciones a eventos específicos para recibir notificaciones push cada vez que ocurre un evento significativo en un partido (ej., un hit, una carrera, un cambio de entrada).

**Implementación en Flutter:**

*   **Streams y Sockets:** La comunicación con la API de SportRadar se maneja mediante `Streams` de Dart. Se utiliza la biblioteca `WebSocket` para establecer una conexión bidireccional en tiempo real.

    ```dart
    import 'package:web_socket_channel/web_socket_channel.dart';

    final channel = WebSocketChannel.connect(
      Uri.parse('wss://api.sportradar.com/...'), // URL de SportRadar
    );

    channel.stream.listen((message) {
      // Procesar el mensaje recibido de SportRadar
      updateScore(message);
    });
    ```

*   **Gestión del Estado (State Management):**  Para asegurar que la interfaz de usuario refleje los datos más recientes, se utiliza un sistema de gestión de estado reactivo (como `Provider` o `Bloc`).  Cuando se recibe una actualización de la API, se actualiza el estado de la aplicación, lo que provoca una reconstrucción de los widgets relevantes.

*   **Manejo de Errores:** Se han implementado mecanismos robustos de manejo de errores para garantizar que la aplicación pueda recuperarse de errores de conexión o datos inesperados. Esto incluye la re-conexión automática a la API y la visualización de mensajes de error informativos al usuario.

*   **Optimización del Rendimiento:**  Para evitar un consumo excesivo de recursos, se han implementado técnicas de optimización del rendimiento, como la limitación de la frecuencia de las actualizaciones de la interfaz de usuario y la utilización de `ListView.builder` para renderizar las listas de eventos de forma eficiente.

**Consideraciones de la API de SportRadar:**

*   Es esencial tener una clave de API válida de SportRadar para acceder a los datos en tiempo real. Esta clave debe configurarse correctamente en la aplicación.
*   La API de SportRadar tiene límites de frecuencia.  La aplicación debe estar diseñada para manejar estos límites y evitar excederlos.

**Visualización de Datos:**

Los datos de los marcadores se presentan de forma clara y concisa en la interfaz de usuario. Esto incluye el marcador actual, el estado del partido (ej., entrada actual, número de outs), y otra información relevante.  Se utilizan widgets personalizados para mostrar los datos de forma visualmente atractiva.

**Ejemplo de Datos Recibidos:**

Aunque el formato exacto depende de SportRadar, un ejemplo simplificado podría ser:

```json
{
  "game_id": "12345",
  "inning": 7,
  "inning_half": "bottom",
  "home_score": 3,
  "away_score": 2,
  "outs": 2,
  "strikes": 1,
  "balls": 3
}
```

Este JSON se deserializa y se usa para actualizar los widgets correspondientes en la aplicación.

## Partidos del día

La funcionalidad de 'Partidos del día' es el núcleo de EpicSports, proporcionando a los usuarios una vista completa de los juegos de la MLB programados para el día en curso. Esta sección detalla cómo se implementa esta funcionalidad y cómo los usuarios pueden interactuar con ella.

**Características Clave:**

*   **Visualización Integral:** Muestra todos los partidos programados para el día actual, organizados cronológicamente para una fácil navegación.
*   **Información Detallada:** Cada partido muestra información esencial, incluyendo los equipos participantes (local y visitante), la hora de inicio programada (convertida a la zona horaria del usuario), y el estado del partido (por ejemplo, 'Por comenzar', 'En Juego', 'Finalizado').
*   **Integración con Marcadores en Tiempo Real:** Al seleccionar un partido de la lista, los usuarios son redirigidos a la vista de 'Marcadores en Tiempo Real', donde pueden seguir el desarrollo del juego con actualizaciones minuto a minuto (ver la sección 'Marcadores en Tiempo Real' para más detalles).
*   **Notificaciones Push (Integración Futura):** Aunque no está implementado actualmente, planeamos integrar notificaciones push para recordar a los usuarios sobre los partidos próximos y proporcionar actualizaciones importantes durante los juegos (por ejemplo, cambios de puntaje, finales de entrada).

**Implementación Técnica:**

*   **Fuente de Datos:** Los datos de los partidos se obtienen a través de la API de Sport Radar, específicamente utilizando los endpoints diseñados para obtener la programación diaria de la MLB.
*   **Manejo de Fechas:** Se utiliza la librería `intl` de Flutter para formatear y convertir las fechas y horas de los partidos a la zona horaria local del usuario. Esto asegura una experiencia consistente y relevante, independientemente de la ubicación del usuario.
*   **Estado de los Partidos:** La lógica de la aplicación evalúa el estado actual de cada partido basándose en los datos proporcionados por la API. Esto permite mostrar etiquetas precisas como 'Por Comenzar', 'En Juego' o 'Finalizado'.
*   **Actualización de Datos:** La vista 'Partidos del Día' se actualiza automáticamente a intervalos regulares (ej., cada 5 minutos) para reflejar cualquier cambio en la programación (ej., retrasos debido al clima).

**Ejemplo de Uso:**

Al abrir la aplicación EpicSports, la vista predeterminada es 'Partidos del Día', proporcionando acceso inmediato a la programación del día. Los usuarios pueden desplazarse verticalmente para explorar todos los partidos. Al tocar un partido específico, la aplicación navega automáticamente a la vista de 'Marcadores en Tiempo Real' para ese juego.

**Código de Ejemplo (Obtención de Partidos - Pseudocódigo):**

```dart
Future<List<Match>> getTodaysMatches() async {
  // Llamar a la API de Sport Radar para obtener los partidos del día.
  final response = await http.get(Uri.parse('https://api.sportradar.com/mlb/official/trial/v7/en/schedules/{YYYY-MM-DD}/schedule.json?api_key={YOUR_API_KEY}'));

  if (response.statusCode == 200) {
    // Parsear la respuesta JSON y mapearla a una lista de objetos `Match`.
    final jsonData = jsonDecode(response.body);
    List<Match> matches = jsonData['games'].map((game) => Match.fromJson(game)).toList();
    return matches;
  } else {
    // Manejar errores (ej., mostrar un mensaje de error al usuario).
    throw Exception('Failed to load matches');
  }
}
```

Este pseudocódigo ilustra el proceso básico de obtención de datos de partidos desde la API de Sport Radar. En la implementación real, se utilizan técnicas de manejo de errores más robustas y se considera la paginación de la API para manejar grandes volúmenes de datos.

## Contribuciones

## Contribuciones

¡Nos encanta recibir contribuciones a EpicSports! Si deseas contribuir, sigue estas pautas:

### Cómo Contribuir

1.  **Fork del Repositorio:**
    *   Haz un fork del repositorio EpicSports en tu propia cuenta de GitHub.

2.  **Clon del Repositorio Forkeado:**
    ```bash
    git clone https://github.com/tu-usuario/EpicSports.git
    cd EpicSports
    ```

3.  **Creación de una Rama:**
    *   Crea una nueva rama para tu contribución. Usa un nombre descriptivo:
    ```bash
    git checkout -b feature/tu-caracteristica
    ```
    o
    ```bash
    git checkout -b fix/tu-arreglo
    ```

4.  **Realización de Cambios:**
    *   Realiza los cambios necesarios en el código. Asegúrate de que tu código siga las convenciones de estilo del proyecto (Flutter).
    *   Escribe pruebas unitarias para tu código, si es aplicable.

5.  **Commit de los Cambios:**
    *   Haz commit de tus cambios con mensajes descriptivos. Sigue estas pautas:
        *   Usa un título conciso (máximo 50 caracteres).
        *   Proporciona una descripción más detallada en el cuerpo del mensaje.
    ```bash
    git add .
    git commit -m "feat: Agrega la funcionalidad X"
    ```

6.  **Rebase con la Rama Principal (opcional pero recomendado):**
    *   Antes de enviar tu Pull Request, considera hacer rebase con la rama `main` para evitar conflictos:
    ```bash
    git fetch origin
    git rebase origin/main
    ```

7.  **Push a tu Repositorio:**
    *   Sube tu rama a tu repositorio fork en GitHub:
    ```bash
    git push origin feature/tu-caracteristica
    ```

8.  **Apertura de un Pull Request:**
    *   Abre un Pull Request desde tu rama en tu repositorio fork a la rama `main` del repositorio original de EpicSports.
    *   Proporciona una descripción clara de tus cambios y su propósito en el Pull Request.

### Pautas de Contribución

*   **Estilo de Código:** Sigue las convenciones de estilo de Flutter.
*   **Pruebas:** Escribe pruebas unitarias para tu código.
*   **Documentación:** Documenta tu código claramente.
*   **Mensajes de Commit:** Usa mensajes de commit descriptivos.
*   **Comunicación:** Sé respetuoso y comunicativo en las discusiones.

### Proceso de Revisión

*   Los mantenedores del proyecto revisarán tu Pull Request.
*   Se te puede pedir que realices cambios adicionales.
*   Una vez aprobado, tu Pull Request será mergeado.

¡Gracias por tu contribución a EpicSports!

## Licencia

EpicSports está licenciado bajo la Licencia MIT.

Copyright (c) 2025 [SanBenito12]

Por la presente se otorga permiso, libre de cargo, a cualquier persona que obtenga una copia
de este software y los archivos de documentación asociados (el "Software"), para tratar
el Software sin restricción, incluyendo sin limitación los derechos
de usar, copiar, modificar, fusionar, publicar, distribuir, sublicenciar, y/o vender
copias del Software, y para permitir a las personas a quienes se les proporcione
el Software a hacer lo mismo, sujeto a las siguientes condiciones:

El aviso de copyright anterior y este aviso de permiso se incluirán en
todas las copias o partes sustanciales del Software.

EL SOFTWARE SE PROPORCIONA "TAL CUAL", SIN GARANTÍA DE NINGÚN TIPO, EXPRESA O
IMPLÍCITA, INCLUYENDO PERO NO LIMITADO A LAS GARANTÍAS DE COMERCIABILIDAD,
IDONEIDAD PARA UN PROPÓSITO PARTICULAR Y NO INFRACCIÓN. EN NINGÚN CASO EL
AUTORES O TITULARES DEL COPYRIGHT SERÁN RESPONSABLES POR CUALQUIER RECLAMACIÓN, DAÑOS U OTRA
RESPONSABILIDAD, YA SEA EN UNA ACCIÓN DE CONTRATO, AGRAVIO O DE OTRO MODO, QUE SURJA DE,
FUERA DE O EN CONEXIÓN CON EL SOFTWARE O EL USO U OTRO TIPO DE ACCIONES EN EL SOFTWARE.


