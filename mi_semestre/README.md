# OrganiU

Aplicación móvil Android para estudiantes universitarios: horario de clases, tareas/exámenes,
recordatorios, simulador de nota final, exportación a calendario y acceso al formulario de
asistencia. Toda la organización funciona **100 % sin conexión**, guarda todo en el teléfono y
**no requiere cuenta**; solo el formulario de asistencia necesita internet.

Proyecto del curso **Programación Móvil**, propiedad de **Rooney M. Mayorga**.
Construida con **Flutter 3.50 / Dart 3.14**.

> El nombre visible es **OrganiU**. El paquete, la base de datos y el prefijo QR siguen usando
> `mi_semestre` para conservar los datos y los códigos ya compartidos.

## Funcionalidades (MVP)

- **Hoy**: clase en curso o próxima clase con cuenta regresiva, clases del día, entregas de los próximos 7 días y botón **Asistencia de Clases** que abre el formulario de Microsoft Forms ya existente.
- **Horario**: vista por día (lunes a domingo) con bloques por materia, aula, docente y total de horas.
- **Tareas**: exámenes, entregas, proyectos y exposiciones; filtro por pendientes/hechas; notas y ponderación.
- **Materias**: CRUD con color, docente y aula; promedio ponderado por materia.
- **Recordatorios**: notificación local X minutos antes de cada entrega (5 min a 1 día antes), aviso a la hora de entrega si la fecha está muy cerca y resumen diario de tareas pendientes. El permiso de notificaciones se solicita al abrir la app.
- **Ajustes**: tema claro/oscuro/sistema, permiso de notificaciones, notificación de prueba.
- **Respaldo**: exportar/importar todos los datos como JSON usando el portapapeles.
- **Simulador de nota final**: calcula qué nota necesitas en las evaluaciones pendientes, con
  escala 0–10 o 0–100 y ponderaciones.
- **Choques de horario**: al guardar un bloque avisa si se cruza con otra clase y permite
  confirmar o cancelar.
- **Calendario**: exporta las entregas pendientes como un archivo `.ics` para abrirlo en el
  calendario del teléfono.
- **Horario por QR**: opcional; muestra tu horario como QR o escanea el de otro estudiante para
  agregar materias y bloques sin borrar tus datos. No incluye notas ni tareas.

## Instalar el APK en el teléfono

Los APK compilados están en la carpeta `dist/`:

| Archivo | Cuándo usarlo |
|---|---|
| `OrganiU-1.0.1-arm64-v8a.apk` (25.5 MB) | **Recomendado**: casi todos los teléfonos Android modernos |
| `OrganiU-1.0.1-armeabi-v7a.apk` (21.9 MB) | Teléfonos antiguos de 32 bits |
| `OrganiU-1.0.1-universal.apk` (69.8 MB) | Si no sabes qué arquitectura tiene el equipo |

Pasos:

1. Copia el APK al teléfono (cable USB, Google Drive, WhatsApp a ti mismo, etc.).
2. Ábrelo desde el explorador de archivos.
3. Si Android lo pide, activa **"Instalar apps desconocidas"** para la app con la que lo abriste.
4. Al abrir OrganiU 1.0.1, acepta el permiso de **notificaciones** que se solicita automáticamente. Si lo rechazaste antes, ve a Ajustes de Android > OrganiU > Notificaciones y actívalo.
5. Si vas a escanear horarios, acepta el permiso de **cámara** cuando la app lo pida.

> El APK está firmado con la clave de depuración de Android. Sirve para instalar y evaluar el
> proyecto; para publicar en Google Play hay que generar una clave de release propia.

## Compilar desde el código

Requisitos instalados en este equipo: Flutter (`C:\src\flutter`), Android SDK (`C:\Android\Sdk`)
y el JDK de Android Studio.

```powershell
cd mi_semestre
flutter pub get
flutter analyze
flutter test
flutter build apk --release                 # APK universal
flutter build apk --release --split-per-abi # APKs por arquitectura (recomendado para compartir)
```

Salida: `build/app/outputs/flutter-apk/`.

Para probar en un teléfono conectado con depuración USB:

```powershell
flutter devices
flutter run --release
```

## Arquitectura

Separación de responsabilidades (presentación / dominio / datos), como pide el curso:

```
lib/
  main.dart                  Arranque: idioma, zonas horarias, notificaciones
  app.dart                   MaterialApp, tema e inyección de estado (InheritedNotifier)
  theme.dart                 Tema Material 3 y paleta de materias
  domain/
    models.dart              Subject, ScheduleBlock, Assessment (Dart puro)
    academic_logic.dart      Reglas: próxima clase, entregas, promedio, simulador y choques
  data/
    app_database.dart        SQLite (sqflite) con 3 tablas e índices
    repository.dart          CRUD, respaldo y fusión de horarios compartidos
  services/
    notification_service.dart  Notificaciones locales (flutter_local_notifications + timezone)
    settings_service.dart      Preferencias (shared_preferences)
    calendar_service.dart      Generación y compartición de archivos .ics
    schedule_share_service.dart  Codificación/validación del QR de horario
    attendance_service.dart      Apertura del formulario de asistencia (URL fija)
  state/app_state.dart       ChangeNotifier: estado global, permiso y sincronización de recordatorios al guardar, restaurar o volver a la app
  ui/                        Pantallas, formularios y widgets reutilizables
test/
  academic_logic_test.dart   17 pruebas unitarias de la lógica académica
  app_smoke_test.dart       3 pruebas de humo de la interfaz (navegación, asistencia y alta de materia)
  notification_sync_test.dart 5 pruebas de permiso, programación y resumen de notificaciones
  attendance_service_test.dart 1 prueba de la URL de asistencia
  calendar_service_test.dart 1 prueba del archivo .ics
  schedule_share_service_test.dart 3 pruebas del QR de horario
```

### Modelo de datos

- `subjects`: id, nombre, docente, aula, color.
- `schedule_blocks`: id, subject_id, día (1–7), minutos de inicio/fin, aula.
- `assessments`: id, subject_id, título, tipo, fecha ISO, completada, nota, ponderación.

### Decisiones de ingeniería

- **Offline-first**: SQLite local; la app nunca depende de internet ni de un backend.
- **Permisos mínimos**: notificaciones y, solo si el usuario elige escanear un QR, cámara.
  Sin ubicación, contactos ni almacenamiento externo. El QR de horario no incluye notas ni tareas.
- **Alarmas inexactas** (`inexactAllowWhileIdle`): evitan pedir el permiso especial de alarmas
  exactas de Android 12+; suficientes para recordatorios académicos.
- **Sin autenticación**: no hay datos sensibles en un servidor; todo queda en el dispositivo.
- **Funciones extra locales**: QR (`qr_flutter` + `mobile_scanner`) y calendario (`share_plus` +
  `path_provider`) no necesitan backend.

## Pruebas

```powershell
flutter analyze   # 0 issues
flutter test      # 30/30 pruebas pasan (lógica, ICS, QR, asistencia, notificaciones y humo de UI)
```

## Siguientes pasos sugeridos

- Widget de pantalla de inicio con la próxima clase.
- Notificaciones del horario (ej. 30 min antes de cada clase).
- Sincronización opcional con Supabase para varios dispositivos.
- Firma release y cifrado de la base de datos para publicación.
