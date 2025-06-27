# EpicSports

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white) ![Android](https://img.shields.io/badge/Android-%233DDC84.svg?style=for-the-badge&logo=android&logoColor=white) ![Push Notifications](https://img.shields.io/badge/Push%20Notifications-orange)

APP HECHA EN FLUTTER PARA ANDROID QUE DA ESTADISTICAS DE PARTIDOS DE MLB USANDO LA API DE SPORT RADAR


## Introducción

EpicSports es una aplicación móvil para Android desarrollada con Flutter, diseñada para ofrecer a los fanáticos del béisbol una experiencia inmersiva y completa siguiendo las estadísticas y resultados de la Major League Baseball (MLB). En un mundo donde la información deportiva es abundante pero a menudo dispersa, EpicSports centraliza los datos más relevantes en una interfaz intuitiva y fácil de usar. 

Esta aplicación resuelve el problema de tener que buscar en múltiples fuentes para obtener actualizaciones de partidos, marcadores en vivo y estadísticas detalladas. EpicSports está dirigida a aficionados del béisbol de todos los niveles, desde el seguidor casual hasta el analista más dedicado. Ofrece desde notificaciones push personalizables para no perderse ni un solo momento clave de los juegos, hasta la posibilidad de consultar los juegos del día y acceder a marcadores actualizados al instante.  

En resumen, EpicSports es la herramienta definitiva para cualquier fanático de la MLB que desee estar al tanto de todo lo que sucede en el mundo del béisbol, de una manera rápida, eficiente y personalizada.

## Características

EpicSports ofrece una variedad de características diseñadas para mantener a los fanáticos de la MLB al tanto de cada juego y estadística. A continuación, se detallan las características clave:

*   **Notificaciones Push:**
    *   Recibe notificaciones instantáneas directamente en tu dispositivo Android sobre momentos importantes de los juegos, como el inicio del juego, actualizaciones de puntaje, finales de entrada y cualquier evento crucial que cambie el curso del juego. Estas notificaciones son altamente configurables, lo que te permite elegir qué tipos de alertas deseas recibir y para qué equipos.
    *   Personaliza tus notificaciones según tus equipos favoritos, para que solo recibas actualizaciones sobre los juegos que más te interesan.
    *   Asegúrate de no perderte nunca un momento crucial, incluso cuando no puedas ver el juego en vivo.

*   **Marcadores Actualizados en Tiempo Real:**
    *   Sigue los marcadores de todos los juegos de la MLB en tiempo real. Los marcadores se actualizan instantáneamente a medida que ocurren los eventos en el juego, proporcionando información precisa y actualizada.
    *   Accede a información detallada del juego, incluyendo carreras, hits, errores (RHE), conteo de outs y estado de las bases.
    *   Consulta las estadísticas del equipo y del jugador directamente desde la pantalla del marcador para obtener una comprensión más profunda del juego.

*   **Juegos del Día:**
    *   Obtén una lista completa de todos los juegos de la MLB programados para el día actual.
    *   Visualiza fácilmente los horarios de los juegos, los enfrentamientos de los lanzadores y los lugares.
    *   Establece recordatorios para los juegos que quieras ver, asegurándote de no perderte el inicio.
    *   Accede rápidamente a los marcadores en vivo de los juegos en curso desde la lista de Juegos del Día.

## Tecnologías

EpicSports está construido utilizando las siguientes tecnologías clave:

*   **Flutter:** El framework de desarrollo de UI de Google. Utilizamos Flutter para construir una aplicación para Android de alto rendimiento y visualmente atractiva desde una única base de código. Flutter nos permite implementar rápidamente nuevas funcionalidades y mantener una experiencia de usuario consistente en diferentes dispositivos Android.

    *   **¿Por qué Flutter?:** Optamos por Flutter debido a su capacidad para crear interfaces de usuario nativas con un desarrollo rápido, una amplia gama de widgets personalizables y un excelente rendimiento. Su arquitectura basada en widgets y el soporte para hot-reload aceleraron significativamente el ciclo de desarrollo.

*   **API de SportRadar:** Esta API proporciona datos deportivos en tiempo real y estadísticos de MLB. La usamos para obtener los marcadores, los juegos del día y otras estadísticas del juego que mostramos en la aplicación. La API de SportRadar es una fuente confiable y completa de datos deportivos, lo que garantiza que EpicSports proporciona información precisa y actualizada.

*   **Notificaciones Push (Firebase Cloud Messaging - FCM):** FCM se utiliza para enviar notificaciones push a los usuarios, manteniéndolos actualizados sobre los marcadores de los partidos en vivo y otros eventos importantes. FCM permite la entrega confiable y eficiente de notificaciones, lo que mejora la participación del usuario y proporciona actualizaciones oportunas.

## Instalación

Para instalar y ejecutar EpicSports en tu entorno local, sigue estos pasos:

### Prerrequisitos

Antes de comenzar, asegúrate de tener instalados los siguientes requisitos:

*   **Flutter SDK:** Asegúrate de tener el SDK de Flutter instalado y configurado correctamente. Puedes descargarlo desde [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install) y seguir las instrucciones de instalación para tu sistema operativo.
*   **Android Studio o Visual Studio Code:** Necesitarás un IDE para desarrollar aplicaciones Flutter. Recomendamos Android Studio o Visual Studio Code con el plugin de Flutter.
*   **Android SDK:** Si usas Android Studio, el Android SDK debería instalarse automáticamente. De lo contrario, asegúrate de tenerlo instalado y configurado.
*   **Git:** Git es necesario para clonar el repositorio. Si no lo tienes instalado, puedes descargarlo desde [https://git-scm.com/](https://git-scm.com/).

### Clonar el Repositorio

Clona el repositorio de EpicSports desde GitHub:

```bash
git clone [URL_DEL_REPOSITORIO]
cd EpicSports
```

Reemplaza `[URL_DEL_REPOSITORIO]` con la URL real del repositorio de EpicSports.

### Instalar Dependencias

Una vez que hayas clonado el repositorio, navega hasta el directorio del proyecto y ejecuta el siguiente comando para instalar las dependencias de Flutter:

```bash
flutter pub get
```

Este comando descargará todas las dependencias necesarias especificadas en el archivo `pubspec.yaml`.

### Configuración de la API de Sport Radar

EpicSports utiliza la API de Sport Radar para obtener las estadísticas de los partidos de MLB. Deberás obtener una clave de API de Sport Radar y configurarla en la aplicación.

1.  **Obtener una clave de API:** Visita el sitio web de Sport Radar Developer ([https://developer.sportradar.com/](https://developer.sportradar.com/)) y regístrate para obtener una clave de API.
2.  **Configurar la clave de API:** Crea un archivo `.env` en la raíz del proyecto. Agrega la siguiente línea al archivo, reemplazando `YOUR_SPORT_RADAR_API_KEY` con tu clave de API:

    ```
    SPORT_RADAR_API_KEY=YOUR_SPORT_RADAR_API_KEY
    ```

    Asegúrate de que este archivo `.env` esté incluido en tu archivo `.gitignore` para evitar que tu clave de API se suba a un repositorio público.

3.  **Cargar la clave de API en la aplicación:** Necesitarás cargar esta clave de API desde el archivo `.env` en tu código Flutter. Puedes usar un paquete como `flutter_dotenv` para hacer esto. Agrega la dependencia a tu `pubspec.yaml`:

    ```yaml
    dependencies:
      flutter_dotenv: ^5.0.2
    ```

    Luego, ejecuta `flutter pub get` para instalar la dependencia.

    En tu archivo `main.dart` (o donde sea apropiado), carga las variables de entorno:

    ```dart
    import 'package:flutter_dotenv/flutter_dotenv.dart';

    Future<void> main() async {
      await dotenv.load(fileName: ".env");
      runApp(MyApp());
    }
    ```

    Finalmente, accede a la clave de API en tu código:

    ```dart
    final apiKey = dotenv.env['SPORT_RADAR_API_KEY'];
    ```

### Ejecutar la Aplicación

Con todos los requisitos previos instalados y las dependencias configuradas, puedes ejecutar la aplicación en un emulador o en un dispositivo físico.

```bash
flutter run
```

Este comando compilará y ejecutará la aplicación en el dispositivo conectado o en el emulador. Asegúrate de tener un emulador configurado o un dispositivo Android conectado y reconocido por tu sistema.

Si tienes problemas, consulta la documentación de Flutter para obtener más información sobre la configuración y el uso: [https://flutter.dev/docs](https://flutter.dev/docs).

## Uso

## Uso

Para utilizar la aplicación EpicSports, siga estos pasos:

1.  **Instalación:** Asegúrese de haber seguido las instrucciones de la sección [Instalación](#instalación) para configurar correctamente el entorno de desarrollo de Flutter y tener la aplicación instalada en su dispositivo Android (emulador o físico).

2.  **Ejecución de la Aplicación:**

    *   Abra su emulador de Android o conecte su dispositivo Android a su computadora.
    *   En la terminal, navegue hasta el directorio raíz del proyecto EpicSports.
    *   Ejecute la aplicación utilizando el siguiente comando:

        ```bash
        flutter run
        ```

    *   Este comando compilará y ejecutará la aplicación en el dispositivo o emulador seleccionado.

3.  **Navegación en la Aplicación:**

    *   Una vez que la aplicación se haya iniciado, verá la pantalla principal.
    *   **Marcadores Actualizados:** La pantalla principal mostrará los marcadores actualizados de los juegos de la MLB en curso.  Estos marcadores se actualizan automáticamente en tiempo real, proporcionando la información más reciente.
    *   **Juegos del Día:** Podrá ver una lista de los juegos programados para el día actual.

4.  **Notificaciones Push:**

    *   Asegúrese de haber habilitado las notificaciones para la aplicación EpicSports en la configuración de su dispositivo Android.
    *   Recibirá notificaciones push para eventos importantes de los juegos, tales como el inicio de un juego, cambios en el marcador, y el final de un juego.

5.  **Ejemplo de Uso:**

    Imagine que desea seguir un juego específico entre los Dodgers y los Yankees.  
    *   Abra la aplicación EpicSports.
    *   En la pantalla principal, busque el juego Dodgers vs. Yankees en la lista de juegos.
    *   Verá el marcador actual del juego, que se actualiza automáticamente a medida que avanza el juego.
    *   Si habilitó las notificaciones, recibirá una notificación push si un equipo anota o si hay algún otro evento importante en el juego.

**Consideraciones Adicionales:**

*   **Conexión a Internet:** La aplicación requiere una conexión a Internet activa para recibir los marcadores actualizados y las notificaciones push de la API de Sport Radar.
*   **Configuración de Notificaciones:** Verifique la configuración de notificaciones de la aplicación en su dispositivo Android para asegurarse de que las notificaciones estén habilitadas para EpicSports.

## Notificaciones Push

Las notificaciones push son una parte integral de la experiencia de usuario en EpicSports. Permiten a los usuarios mantenerse al tanto de los últimos acontecimientos en el mundo de la MLB, incluso cuando no están activamente usando la aplicación. A continuación, se detalla cómo funcionan las notificaciones push en EpicSports:

### Funcionalidad Principal

*   **Alertas de Marcadores en Vivo:** Los usuarios reciben notificaciones instantáneas cuando un partido alcanza momentos clave, como el final de una entrada, un cambio de liderazgo o un resultado final. Estas notificaciones se envían en tiempo real, garantizando que los usuarios estén siempre informados.
*   **Recordatorios de Juegos:** La aplicación permite a los usuarios configurar recordatorios para los juegos que les interesan. Recibirán una notificación push antes de que comience el juego, asegurándose de que no se pierdan el inicio de la acción.
*   **Noticias y Actualizaciones:** Los usuarios también pueden optar por recibir notificaciones sobre noticias relevantes de la MLB, como traspasos de jugadores, lesiones importantes o anuncios importantes de la liga.

### Implementación Técnica

Las notificaciones push en EpicSports se implementan utilizando Firebase Cloud Messaging (FCM). FCM proporciona una forma confiable y eficiente de enviar notificaciones push a dispositivos Android. Aquí hay una descripción general de los pasos involucrados:

1.  **Registro del Dispositivo:** Cuando un usuario inicia la aplicación por primera vez, la aplicación registra el dispositivo con FCM y obtiene un token de registro único.
2.  **Almacenamiento del Token:** Este token de registro se almacena en nuestra base de datos backend, asociado con la cuenta del usuario.
3.  **Envío de Notificaciones:** Cuando se produce un evento que desencadena una notificación push (por ejemplo, un cambio de puntaje), nuestro backend envía un mensaje a FCM, especificando el token de registro del dispositivo de destino y el contenido de la notificación.
4.  **Entrega de la Notificación:** FCM entrega la notificación al dispositivo del usuario, donde la aplicación la muestra al usuario.

### Personalización

Los usuarios tienen control total sobre las notificaciones que reciben. Pueden habilitar o deshabilitar diferentes tipos de notificaciones en la configuración de la aplicación. Esto garantiza que solo reciban las notificaciones que les interesan.

### Manejo de Errores

La aplicación incluye manejo de errores robusto para garantizar que las notificaciones push se entreguen de manera confiable. Si una notificación no se entrega (por ejemplo, si el dispositivo está fuera de línea), la aplicación intentará volver a enviarla más tarde. También monitoreamos las tasas de entrega de notificaciones para identificar y resolver cualquier problema.

### Ejemplo de Código (Flutter)

Aquí hay un fragmento de código Flutter que muestra cómo inicializar Firebase Messaging y solicitar permiso para enviar notificaciones push:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Solicitar permiso para enviar notificaciones push
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission!');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional permission');
  } else {
    print('User declined or has not accepted permission');
  }

  // Obtener el token de registro
  String? token = await messaging.getToken();
  print('Registration Token: $token');

  runApp(MyApp());
}
```

Este código solicita permiso al usuario para enviar notificaciones push y luego imprime el token de registro del dispositivo. Este token se puede utilizar para enviar notificaciones push dirigidas a dispositivos específicos.

## Juegos del Día

La funcionalidad 'Juegos del Día' en EpicSports es el núcleo de la experiencia para los fanáticos de la MLB que buscan información rápida y relevante sobre los partidos más importantes del día. Esta sección de la aplicación proporciona una vista concisa y actualizada de los juegos programados, incluyendo:

*   **Listado Completo de Partidos:**  Muestra todos los juegos de MLB programados para el día actual.  Esto incluye información esencial como los equipos que se enfrentan (local vs. visitante), la hora de inicio del partido (convertida automáticamente a la zona horaria del usuario), y el estado actual del juego (programado, en curso, finalizado, pospuesto, etc.).

*   **Información Detallada del Juego:**  Al seleccionar un juego específico de la lista, el usuario puede acceder a una vista más detallada que incluye información como:
    *   **Marcador en Vivo:**  Actualizaciones en tiempo real del marcador, incluyendo carreras, hits y errores.
    *   **Estadísticas Clave del Juego:**  Información estadística relevante, como el conteo de strikes y bolas, el número de outs, el corredor en base y las estadísticas de bateo y lanzamiento más recientes.
    *   **Alineaciones de los Equipos:**  Las alineaciones iniciales de cada equipo, con información sobre los jugadores titulares y sus posiciones.
    *   **Información del Lanzador:**  Detalles sobre los lanzadores abridores y relevistas, incluyendo sus estadísticas de temporada y su rendimiento en el juego actual.
    *   **Notificaciones Personalizadas:**  Opción para activar notificaciones push específicas para un juego, permitiendo al usuario recibir alertas sobre momentos clave, como el inicio del juego, cambios de marcador importantes, o el final del juego.

*   **Interfaz Intuitiva y Fácil de Usar:**  La presentación de la información está diseñada para ser clara y concisa, permitiendo a los usuarios encontrar rápidamente los juegos que les interesan y acceder a la información que necesitan sin complicaciones. La interfaz se adapta a diferentes tamaños de pantalla y orientaciones para una experiencia óptima en cualquier dispositivo Android.

*   **Integración con Notificaciones Push:**  Los usuarios pueden configurar notificaciones push para recibir alertas sobre los juegos del día.  Esto incluye recordatorios antes del inicio del partido, actualizaciones de marcadores en tiempo real y notificaciones de final de partido.  Estas notificaciones son altamente personalizables, permitiendo a los usuarios elegir los juegos y los tipos de eventos sobre los que desean recibir alertas.

Esta funcionalidad está construida con Flutter para garantizar un rendimiento óptimo y una experiencia de usuario fluida en dispositivos Android.

## Marcadores Actualizados

La funcionalidad de 'Marcadores Actualizados' en EpicSports proporciona a los usuarios información en tiempo real sobre los resultados de los partidos de la MLB. Esta característica es crucial para los fanáticos que desean seguir la acción a medida que se desarrolla, independientemente de su ubicación o la disponibilidad de transmisiones televisivas.

**Características Clave:**

*   **Actualizaciones en Tiempo Real:** Los marcadores se actualizan dinámicamente durante los juegos, reflejando cada carrera, hit y out a medida que suceden. Esto garantiza que los usuarios siempre tengan la información más precisa y actualizada.

*   **Notificaciones Push:** Opcionalmente, los usuarios pueden habilitar las notificaciones push para recibir alertas instantáneas sobre cambios importantes en el juego, como el final de una entrada, carreras anotadas o cambios en el marcador. Esto permite a los fanáticos mantenerse informados sin tener que monitorear constantemente la aplicación.

*   **Visualización Detallada del Juego:** Más allá de los marcadores básicos, la función ofrece información detallada del juego, como el conteo de bolas y strikes, quién está al bate, la situación de las bases y estadísticas relevantes del juego. Esto proporciona un contexto más profundo para el marcador y mejora la experiencia del usuario.

*   **Personalización:** Los usuarios pueden personalizar su experiencia seleccionando sus equipos favoritos y priorizando los juegos que desean seguir más de cerca. Esto asegura que reciban las actualizaciones más relevantes para sus intereses.

*   **Acceso a Resultados Anteriores:** Además de los marcadores en vivo, la función permite a los usuarios acceder a los resultados de juegos anteriores. Esto es útil para los fanáticos que se perdieron un juego o desean revisar el desempeño de su equipo en juegos recientes.

**Implementación Técnica:**

La implementación de 'Marcadores Actualizados' se basa en la API de Sport Radar, que proporciona una fuente confiable y precisa de datos de la MLB. La aplicación Flutter consulta esta API de manera regular para obtener las últimas actualizaciones del juego y las muestra a los usuarios en un formato fácil de entender.

El uso de `StreamBuilder` en Flutter permite actualizar la información en la UI de forma reactiva cada vez que la API de Sport Radar provee nueva información. Esto permite evitar refrescos innecesarios en la UI y mejorar la experiencia de usuario.

```dart
StreamBuilder(
  stream: sportRadarApi.getLiveScores(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return LiveScoreWidget(scores: snapshot.data);
    } else if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    } else {
      return CircularProgressIndicator();
    }
  },
)
```

El manejo de errores y la gestión del estado se implementan cuidadosamente para garantizar que la aplicación sea robusta y confiable, incluso en condiciones de red desfavorables.


## Contribuciones

## Contribuciones

¡Nos encanta que quieras contribuir a EpicSports! Aquí te explicamos cómo puedes hacerlo.

### Cómo contribuir

1.  **Haz un fork del repositorio:**

    En la página del repositorio de EpicSports en GitHub, haz clic en el botón "Fork" en la esquina superior derecha. Esto creará una copia del repositorio en tu propia cuenta de GitHub.

2.  **Clona tu fork localmente:**

    Usa `git` para clonar el repositorio a tu máquina local.

    ```bash
    git clone https://github.com/tu-usuario/EpicSports.git
    cd EpicSports
    ```

3.  **Crea una rama para tus cambios:**

    Es importante crear una rama separada para cada contribución. Esto mantiene el `main` branch limpio y facilita la revisión de tus cambios.

    ```bash
    git checkout -b feature/tu-nueva-caracteristica
    ```

    O, si estás arreglando un bug:

    ```bash
    git checkout -b fix/descripcion-del-bug
    ```

4.  **Realiza tus cambios:**

    Implementa los cambios que deseas aportar. Asegúrate de que tu código siga las convenciones del proyecto y esté bien comentado.

5.  **Realiza commits con mensajes descriptivos:**

    Escribe mensajes de commit claros y concisos que expliquen lo que has cambiado. Un buen mensaje de commit sigue estas pautas:

    *   Comienza con un verbo en imperativo (ej., "Añade", "Corrige", "Actualiza").
    *   Describe brevemente el cambio (máximo 50 caracteres).
    *   Opcionalmente, añade una explicación más detallada en el cuerpo del mensaje.

    ```bash
    git add .
    git commit -m "Añade: Implementa la función de notificaciones push"
    ```

6.  **Sube tus cambios a tu fork en GitHub:**

    ```bash
    git push origin feature/tu-nueva-caracteristica
    ```

7.  **Crea un Pull Request:**

    En tu fork del repositorio en GitHub, haz clic en el botón "Compare & pull request". Asegúrate de describir claramente tus cambios y el problema que resuelven. También puedes mencionar a colaboradores específicos para que revisen tu Pull Request.

### Directrices de contribución

*   **Estilo de código:** Por favor, sigue el estilo de código existente en el proyecto.  Considera usar las herramientas de formateo de código disponibles para Flutter para mantener la consistencia.
*   **Pruebas:** Si añades nuevas funcionalidades, considera añadir pruebas unitarias o de integración para asegurar la calidad del código.
*   **Documentación:** Si cambias APIs o añades nuevas funcionalidades, por favor, actualiza la documentación correspondiente.
*   **Comunicación:** Si tienes alguna pregunta o duda, no dudes en abrir un issue en GitHub.

### Proceso de revisión

Una vez que hayas creado un Pull Request, los mantenedores del proyecto lo revisarán. Pueden solicitar cambios o hacer preguntas sobre tu contribución. Una vez que se hayan resuelto todos los problemas y se haya aprobado el Pull Request, se fusionará en el `main` branch.

¡Gracias por tu contribución a EpicSports!

## Licencia

Este proyecto está licenciado bajo la Licencia MIT - vea el archivo [LICENSE](LICENSE) para más detalles.

```
Copyright (c) 2025 [San Benito]
```

Se concede, de forma gratuita, a cualquier persona que obtenga una copia de este software y de los archivos de documentación asociados (el "Software"), el derecho a utilizar, copiar, modificar, fusionar, publicar, distribuir, sublicenciar y/o vender copias del Software, y a permitir a las personas a las que se les proporcione el Software a hacerlo, sujeto a las siguientes condiciones:

El aviso de copyright anterior y este aviso de permiso se incluirán en todas las copias o partes sustanciales del Software.

EL SOFTWARE SE PROPORCIONA "TAL CUAL", SIN GARANTÍA DE NINGÚN TIPO, EXPRESA O IMPLÍCITA, INCLUIDAS, ENTRE OTRAS, LAS GARANTÍAS DE COMERCIABILIDAD, ADECUACIÓN PARA UN PROPÓSITO PARTICULAR Y NO INFRACCIÓN. EN NINGÚN CASO LOS AUTORES O TITULARES DE LOS DERECHOS DE AUTOR SERÁN RESPONSABLES DE NINGUNA RECLAMACIÓN, DAÑOS U OTRAS RESPONSABILIDADES, YA SEA EN UNA ACCIÓN DE CONTRATO, AGRAVIO O DE OTRO TIPO, QUE SURJAN DE, ESTÉN FUERA DE O EN CONEXIÓN CON EL SOFTWARE O EL USO U OTROS TRATOS EN EL SOFTWARE.


