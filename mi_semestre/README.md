# MiSemestre

Aplicación móvil Android para estudiantes universitarios: horario de clases, tareas/exámenes y
recordatorios. Funciona **100 % sin conexión**, guarda todo en el teléfono y **no requiere cuenta**.

Proyecto del curso **Programación Móvil**. Construida con **Flutter 3.50 / Dart 3.14**.

## Funcionalidades (MVP)

- **Hoy**: clase en curso o próxima clase con cuenta regresiva, clases del día y entregas de los próximos 7 días.
- **Horario**: vista por día (lunes a domingo) con bloques por materia, aula, docente y total de horas.
- **Tareas**: exámenes, entregas, proyectos y exposiciones; filtro por pendientes/hechas; notas y ponderación.
- **Materias**: CRUD con color, docente, aula y créditos; promedio ponderado por materia.
- **Recordatorios**: notificación local X minutos antes de cada entrega (5 min a 1 día antes).
- **Ajustes**: tema claro/oscuro/sistema, permiso de notificaciones, notificación de prueba.
- **Respaldo**: exportar/importar todos los datos como JSON usando el portapapeles.

## Instalar el APK en el teléfono

Los APK compilados están en la carpeta `dist/`:

| Archivo | Cuándo usarlo |
|---|---|
| `MiSemestre-1.0.0-arm64-v8a.apk` (18.8 MB) | **Recomendado**: casi todos los teléfonos Android modernos |
| `MiSemestre-1.0.0-armeabi-v7a.apk` (16.7 MB) | Teléfonos antiguos de 32 bits |
| `MiSemestre-1.0.0-universal.apk` (53.6 MB) | Si no sabes qué arquitectura tiene el equipo |

Pasos:

1. Copia el APK al teléfono (cable USB, Google Drive, WhatsApp a ti mismo, etc.).
2. Ábrelo desde el explorador de archivos.
3. Si Android lo pide, activa **"Instalar apps desconocidas"** para la app con la que lo abriste.
4. Al abrir MiSemestre, acepta el permiso de **notificaciones** para recibir los recordatorios.

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
    academic_logic.dart      Reglas: próxima clase, entregas próximas/vencidas, promedio
  data/
    app_database.dart        SQLite (sqflite) con 3 tablas e índices
    repository.dart          CRUD + exportar/importar respaldo
  services/
    notification_service.dart  Notificaciones locales (flutter_local_notifications + timezone)
    settings_service.dart      Preferencias (shared_preferences)
  state/app_state.dart       ChangeNotifier: estado global y sincronización de recordatorios
  ui/                        Pantallas, formularios y widgets reutilizables
test/
  academic_logic_test.dart   12 pruebas unitarias de la lógica académica
  app_smoke_test.dart       3 pruebas de humo de la interfaz (navegación y alta de materia)
```

### Modelo de datos

- `subjects`: id, nombre, docente, aula, color, créditos.
- `schedule_blocks`: id, subject_id, día (1–7), minutos de inicio/fin, aula.
- `assessments`: id, subject_id, título, tipo, fecha ISO, completada, nota, ponderación.

### Decisiones de ingeniería

- **Offline-first**: SQLite local; la app nunca depende de internet ni de un backend.
- **Permisos mínimos**: solo notificaciones. Sin ubicación, cámara, contactos ni almacenamiento externo.
- **Alarmas inexactas** (`inexactAllowWhileIdle`): evitan pedir el permiso especial de alarmas
  exactas de Android 12+; suficientes para recordatorios académicos.
- **Sin autenticación**: no hay datos sensibles en un servidor; todo queda en el dispositivo.

## Pruebas

```powershell
flutter analyze   # 0 issues
flutter test      # 15/15 pruebas pasan (lógica + humo de UI)
```

## Siguientes pasos sugeridos

- Widget de pantalla de inicio con la próxima clase.
- Compartir horario por QR (`qr_flutter` + `mobile_scanner`).
- Notificaciones del horario (ej. 30 min antes de cada clase).
- Sincronización opcional con Supabase para varios dispositivos.
