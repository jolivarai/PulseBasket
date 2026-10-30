import 'models/exercise.dart';
import 'models/routine_day.dart';

/// Plan semanal por defecto (editable desde la app).
///
/// Criterios de selección:
///  - Nivel intermedio, sin material salvo colchoneta.
///  - Sesiones de fuerza de ~30 min (5 min de calentamiento + 22-25 min de
///    trabajo + 2-3 min de vuelta a la calma).
///  - Progresión medible en 30 días (repeticiones, tempo y unilateralidad).
///  - Transferencia directa a básquet: estabilidad lumbo-pélvica, potencia de
///    empuje/tracción, rigidez de core para frenadas y cambios de dirección.
///
/// Las referencias metodológicas (McGill, Boyle, EXOS, Grover, P3) son
/// atribuciones de escuela de entrenamiento, NO programas oficiales ni
/// afiliaciones: ver docs/RUTINA.md.
const List<RoutineDay> kSeedWeek = [
  // ───────────────────────────────────────────────────────────── LUNES ──
  RoutineDay(
    weekday: 1,
    title: 'Bici + Espalda y dorsales',
    type: WorkoutType.bike,
    targetDistanceMeters: 12000,
    note: 'Calentamiento 5 min: círculos de hombros, gato-camello y 10 '
        'sentadillas al aire. Termina con 2 min de estiramiento de dorsal en '
        'posición fetal.',
    exercises: [
      Exercise(
        id: 'lun-birddog',
        name: 'Bird dog lento',
        muscleGroup: 'Core / Espalda',
        sets: 3,
        reps: '8 por lado',
        restSeconds: 45,
        steps: [
          'En cuadrupedia: manos bajo hombros, rodillas bajo caderas, colchoneta apoyada en el suelo.',
          'Aprieta el abdomen como si fueras a recibir un golpe suave y mantén la espalda plana (sin arquear el lumbar).',
          'Extiende a la vez el brazo derecho y la pierna izquierda, sin girar la cadera.',
          'Mantén 3 segundos arriba con el pulgar mirando al techo, y vuelve en 3 segundos.',
          'Cambia de lado sin tocar el suelo con la rodilla si puedes; si no, apoya y reinicia.',
        ],
        cue: 'Imagina que llevas un vaso de agua sobre el lumbar: si la cadera gira, se derrama.',
        basketballTransfer:
            'Enseña a estabilizar el tronco mientras brazos y piernas se mueven solos, que es exactamente lo que ocurre al botar o al recibir un pase en carrera.',
        source: 'Dr. Stuart McGill (Big 3, estabilidad espinal)',
        easier: 'Extiende solo el brazo, o solo la pierna.',
        harder: 'Traza un círculo pequeño con la mano extendida sin mover el tronco.',
      ),
      Exercise(
        id: 'lun-superman',
        name: 'Superman con tirón',
        muscleGroup: 'Espalda / Dorsales',
        sets: 4,
        reps: '10',
        restSeconds: 45,
        steps: [
          'Boca abajo, brazos extendidos al frente, frente apoyada en una toalla enrollada.',
          'Activa glúteos y separa pubis del suelo 2 cm: ese es el punto de partida, no eleves más el lumbar.',
          'Eleva pecho y brazos del suelo mientras llevas los codos hacia las costillas (como remando).',
          'Aprieta los omóplatos 2 segundos arriba y baja en 3 segundos.',
          'Cuello largo: la barbilla no debe adelantarse a las manos.',
        ],
        cue: 'El movimiento nace de los omóplatos, no de arquear la espalda.',
        basketballTransfer:
            'Fortalece erectores y romboides, la base para mantener el torso firme al absorber contactos y al pelear un rebote.',
        source: 'Mike Boyle (MBSC, fuerza funcional)',
        easier: 'Eleva solo brazos, con el pecho apoyado.',
        harder: 'Pausa de 3 s arriba y piernas también elevadas.',
      ),
      Exercise(
        id: 'lun-prone-row',
        name: 'Remo prone en colchoneta',
        muscleGroup: 'Dorsales / Romboides',
        sets: 4,
        reps: '12',
        restSeconds: 45,
        steps: [
          'Boca abajo, brazos en cruz (forma de T), palmas hacia el suelo.',
          'Sin despegar el pecho más de lo necesario, presiona las palmas contra la colchoneta y lleva los codos hacia atrás y abajo.',
          'Detén cuando los codos pasen ligeramente la línea del torso; no encojas los hombros hacia las orejas.',
          'Aprieta 2 segundos y vuelve controlando 3 segundos.',
          'Respira: suelta el aire al remarcar la contracción.',
        ],
        cue: 'Piensa en "guardar los omóplatos en el bolsillo trasero".',
        basketballTransfer:
            'Contrarresta la postura cerrada de hombros del tirador y da estabilidad para empujar y proteger el balón.',
        source: 'EXOS (Mark Verstegen, movimiento prep)',
        easier: 'Reduce el rango: codos a 45° del torso.',
        harder: 'Pausa de 3 s con codos pegados y muñecas activas.',
      ),
      Exercise(
        id: 'lun-ytw',
        name: 'Y-T-W en prono',
        muscleGroup: 'Trapecio inferior / Hombro',
        sets: 3,
        reps: '8 por letra',
        restSeconds: 40,
        steps: [
          'Boca abajo con la frente apoyada; brazos en Y (diagonal arriba), luego T (cruz) y W (codos flexionados).',
          'En cada letra eleva los brazos 5-10 cm manteniendo el pulgar hacia arriba.',
          'Sostén 2 segundos y baja lento. No hay impulso: si no sube, sube menos.',
          'Completa 8 repeticiones de Y, 8 de T y 8 de W seguidas, sin descanso entre letras.',
          'Descansa 40 s y repite 3 veces.',
        ],
        cue: 'Hombros lejos de las orejas en las tres letras; el cuello no trabaja.',
        basketballTransfer:
            'Estabiliza el hombro en el lanzamiento por encima de la cabeza y en el gesto de tapón.',
        source: 'Peak Performance Project (Dr. Marcus Elliott)',
        easier: 'Solo T y W, sin la Y.',
        harder: 'Añade 1 kg (botella de agua) en cada mano.',
      ),
      Exercise(
        id: 'lun-snowangel',
        name: 'Natación invertida (reverse snow angel)',
        muscleGroup: 'Dorsal ancho / Escápula',
        sets: 3,
        reps: '12',
        restSeconds: 40,
        steps: [
          'Boca abajo, brazos pegados al cuerpo y palmas hacia abajo.',
          'Despega ligeramente manos y brazos y dibuja un arco amplio hasta juntar las manos por encima de la cabeza.',
          'Mantén los brazos a 2-3 cm del suelo durante todo el recorrido: si los apoyas, pierdes tensión.',
          'Vuelve por el mismo camino en 3 segundos, sin tocar la colchoneta.',
          'Respira de forma continua; no aguantes el aire.',
        ],
        cue: 'Recorrido largo y lento; el rango es el objetivo, no la altura.',
        basketballTransfer:
            'Mejora la movilidad activa del hombro en el rango de lanzamiento y la resistencia de la musculatura escapular.',
        source: 'Mike Boyle (MBSC)',
        easier: 'Medio arco: de cadera a hombro.',
        harder: 'Pausa de 2 s en tres posiciones (abajo, medio, arriba).',
      ),
      Exercise(
        id: 'lun-hollow',
        name: 'Hollow hold',
        muscleGroup: 'Core anterior',
        sets: 3,
        reps: '30 s',
        restSeconds: 40,
        steps: [
          'Boca arriba, brazos extendidos por encima de la cabeza y piernas juntas.',
          'Presiona el lumbar contra la colchoneta y súbelo ligeramente del suelo.',
          'Eleva hombros y piernas solo hasta donde puedas mantener el lumbar pegado; empieza con rodillas flexionadas.',
          'Mantén 30 s respirando corto; si el lumbar se despega, baja las piernas.',
          'Descansa 40 s entre series.',
        ],
        cue: 'Si aparece dolor lumbar, no es falta de fuerza: es falta de control. Flexiona más las rodillas.',
        basketballTransfer:
            'Crea la rigidez de tronco que transfiere fuerza de piernas a brazos en el tiro y en el primer paso.',
        source: 'Dr. Stuart McGill / gimnasia (hollow body)',
        easier: 'Rodillas a 90° y brazos a los lados.',
        harder: 'Brazos por encima de la cabeza y piernas más estiradas.',
      ),
      Exercise(
        id: 'lun-facepull',
        name: 'Face pull isométrico con toalla',
        muscleGroup: 'Deltoide posterior',
        sets: 3,
        reps: '20 s',
        restSeconds: 30,
        steps: [
          'Toma una toalla por los extremos con las dos manos, a la altura de la frente.',
          'Tira de la toalla hacia fuera mientras resistes con la otra mano: tensión máxima sin mover las manos.',
          'Abre los codos hacia los lados y lleva los omóplatos hacia la columna.',
          'Mantén 20 s al 70 % de tu fuerza; respira.',
          'Relaja 30 s y repite.',
        ],
        cue: 'Cuello relajado; la tensión está entre los omóplatos, no en la nuca.',
        basketballTransfer:
            'Equilibra el trabajo de pecho y evita el hombro adelantado típico de tantos tiros diarios.',
        source: 'EXOS (prehab de hombro)',
        easier: '15 s al 50 % de fuerza.',
        harder: '30 s al 80 % con codos más abiertos.',
      ),
    ],
  ),

  // ──────────────────────────────────────────────────────────── MARTES ──
  RoutineDay(
    weekday: 2,
    title: 'Carrera 4 km + Pecho, bíceps y tríceps',
    type: WorkoutType.run,
    targetDistanceMeters: 4000,
    note: 'Corre primero (4 km suaves, ritmo conversacional) y luego la fuerza. '
        'Calentamiento de fuerza: 10 círculos de brazos, 10 flexiones fáciles '
        'y 30 s de plancha.',
    exercises: [
      Exercise(
        id: 'mar-pushup',
        name: 'Flexiones estándar',
        muscleGroup: 'Pecho / Tríceps',
        sets: 4,
        reps: '10-12',
        restSeconds: 60,
        steps: [
          'Manos algo más anchas que los hombros, dedos hacia delante, cuerpo en línea recta desde la cabeza a los talones.',
          'Aprieta glúteos y abdomen: la cadera no cae ni sube.',
          'Baja en 2 segundos hasta que el pecho quede a un puño del suelo, codos a 45° del torso.',
          'Empuja el suelo lejos de ti y sube en 1 segundo, sin bloquear los codos de golpe.',
          'La cabeza sigue la línea de la columna: mira al suelo, no al frente.',
        ],
        cue: 'Codos a 45°, nunca en cruz de 90°: protege el hombro.',
        basketballTransfer:
            'Base de fuerza horizontal para empujar en el poste y para el braceo defensivo.',
        source: 'Mike Boyle (MBSC)',
        easier: 'Rodillas apoyadas o manos sobre una superficie elevada.',
        harder: 'Pausa de 3 s abajo o pies elevados.',
      ),
      Exercise(
        id: 'mar-archer',
        name: 'Flexiones arqueras',
        muscleGroup: 'Pecho (unilateral)',
        sets: 3,
        reps: '8 por lado',
        restSeconds: 60,
        steps: [
          'Manos más separadas que en la flexión normal, pies anchos.',
          'Baja hacia la mano derecha flexionando ese codo mientras el izquierdo queda casi extendido.',
          'El pecho baja sobre la mano derecha; la cadera no rota.',
          'Empuja con fuerza y repite hacia el otro lado.',
          'Cuenta 8 repeticiones por lado (16 totales).',
        ],
        cue: 'El brazo extendido actúa de apoyo, no de empuje: trabaja el lado que baja.',
        basketballTransfer:
            'Corrige desequilibrios entre lado dominante y no dominante, clave para un tiro estable.',
        source: 'Calistenia progresiva / P3',
        easier: 'Apoya la rodilla del lado contrario.',
        harder: 'Baja hasta 5 cm del suelo y pausa 1 s.',
      ),
      Exercise(
        id: 'mar-pause-pushup',
        name: 'Flexiones con pausa de 3 s',
        muscleGroup: 'Pecho / Control',
        sets: 3,
        reps: '6',
        restSeconds: 60,
        steps: [
          'Posición de flexión estricta, cuerpo en tabla.',
          'Baja en 3 segundos y detente a 3 cm del suelo.',
          'Mantén 3 segundos completos sin apoyarte y sin perder la línea.',
          'Sube en 1 segundo, con intención rápida.',
          'Son solo 6 repeticiones: la calidad es todo.',
        ],
        cue: 'Temblar está permitido; hundir la cadera, no.',
        basketballTransfer:
            'Aumenta el tiempo bajo tensión y la capacidad de mantener el torso firme en el contacto.',
        source: 'EXOS (tempo training)',
        easier: 'Pausa de 1 s.',
        harder: 'Pausa de 3 s + 2 s de subida.',
      ),
      Exercise(
        id: 'mar-curl-towel',
        name: 'Curl de bíceps con auto-resistencia',
        muscleGroup: 'Bíceps',
        sets: 3,
        reps: '12',
        restSeconds: 45,
        steps: [
          'Sentado en la colchoneta con las piernas cruzadas, agarra una toalla por los extremos.',
          'Con la mano derecha tira de la toalla hacia el hombro mientras la izquierda resiste desde abajo.',
          'Codo pegado al costado: solo se mueve el antebrazo.',
          'Sube en 1 segundo y baja en 3 segundos contra la resistencia de la otra mano.',
          'Haz 12 repeticiones y cambia de brazo sin descansar.',
        ],
        cue: 'La mano que resiste marca el tempo: si bajas rápido, no hay estímulo.',
        basketballTransfer:
            'Fuerza de flexión de codo para proteger el balón y para el gesto de pase con contacto.',
        source: 'Entrenamiento sin material (auto-resistencia)',
        easier: 'Menos resistencia y menos recorrido.',
        harder: 'Excéntrico de 5 s y isométrico final de 20 s.',
      ),
      Exercise(
        id: 'mar-curl-iso',
        name: 'Curl isométrico a 90°',
        muscleGroup: 'Bíceps',
        sets: 3,
        reps: '25 s por brazo',
        restSeconds: 40,
        steps: [
          'Codo flexionado a 90°, antebrazo paralelo al suelo, palma hacia arriba.',
          'Con la otra mano empuja el antebrazo hacia abajo mientras el bíceps resiste sin ceder.',
          'Mantén 25 s con respiración continua y hombro bajo.',
          'Cambia de brazo; descansa 40 s al terminar los dos.',
          'Repite 3 rondas.',
        ],
        cue: 'No aguantes el aire: respiración corta y constante.',
        basketballTransfer:
            'Resistencia isométrica en el ángulo donde el defensor empuja el balón.',
        source: 'Dr. Stuart McGill (isométricos de alta rigidez)',
        easier: '15 s al 60 %.',
        harder: '35 s al 80 %.',
      ),
      Exercise(
        id: 'mar-triceps-floor',
        name: 'Extensión de tríceps en el suelo',
        muscleGroup: 'Tríceps',
        sets: 3,
        reps: '12',
        restSeconds: 45,
        steps: [
          'Tumbado boca arriba, brazos verticales hacia el techo, codos extendidos.',
          'Flexiona los codos llevando las manos hacia la frente, manteniendo los brazos quietos.',
          'Detente cuando los antebrazos pasen la línea de la cabeza y extiende sin bloquear.',
          'Baja en 3 segundos y sube en 1.',
          'Para más tensión, junta las manos y presiona una contra otra.',
        ],
        cue: 'Los codos apuntan al techo y no se abren hacia los lados.',
        basketballTransfer:
            'Extensión de codo potente para el pase de béisbol y para el último tramo del tiro.',
        source: 'Calistenia / aislamiento',
        easier: 'Un brazo a la vez.',
        harder: 'Pausa de 2 s abajo con mancuerna improvisada (botella).',
      ),
      Exercise(
        id: 'mar-dips',
        name: 'Fondos de tríceps en colchoneta',
        muscleGroup: 'Tríceps / Hombro',
        sets: 3,
        reps: '10',
        restSeconds: 50,
        steps: [
          'Sentado, manos detrás de la cadera con dedos hacia delante, rodillas flexionadas.',
          'Eleva la cadera hasta formar una línea recta entre hombros y rodillas.',
          'Flexiona los codos hacia atrás hasta unos 90° sin hundir los hombros.',
          'Empuja para volver arriba apretando el tríceps.',
          'Si molestan las muñecas, gira las manos hacia fuera 45°.',
        ],
        cue: 'Los codos van rectos hacia atrás, no hacia los lados.',
        basketballTransfer:
            'Fuerza de extensión para el empuje en el rebote y para levantarse rápido del suelo tras una caída.',
        source: 'Entrenamiento funcional (Boyle)',
        easier: 'Rodillas más flexionadas y menos recorrido.',
        harder: 'Piernas extendidas y pausa de 2 s abajo.',
      ),
      Exercise(
        id: 'mar-shoulder-tap',
        name: 'Plancha con toque de hombro',
        muscleGroup: 'Core anti-rotación',
        sets: 3,
        reps: '16 (8 por lado)',
        restSeconds: 40,
        steps: [
          'Plancha alta sobre manos, pies algo más anchos que las caderas.',
          'Levanta la mano derecha y toca el hombro izquierdo sin girar la cadera.',
          'Vuelve a apoyar y repite con la otra mano.',
          'Aprieta glúteos para que la pelvis no se balancee.',
          'Ritmo constante: 1 toque cada 2 segundos.',
        ],
        cue: 'Si la cadera se mueve, abre más los pies.',
        basketballTransfer:
            'Anti-rotación pura: evita que el tronco se desalinee al empujar o al recibir falta en el aire.',
        source: 'Dr. Stuart McGill (anti-rotación)',
        easier: 'Con rodillas apoyadas.',
        harder: 'Pies juntos o toque cruzado (mano al hombro contrario).',
      ),
    ],
  ),

  // ────────────────────────────────────────────────────────── MIÉRCOLES ──
  RoutineDay(
    weekday: 3,
    title: 'Bicicleta 12 km',
    type: WorkoutType.bike,
    targetDistanceMeters: 12000,
    note: 'Día sin fuerza. Cadencia cómoda (80-90 rpm) y 5 min finales suaves. '
        'Si llueve, cambia a 3 series de 8 min en bici estática o camina 45 min.',
  ),

  // ───────────────────────────────────────────────────────────── JUEVES ──
  RoutineDay(
    weekday: 4,
    title: 'Carrera 4 km + Abdominales y core',
    type: WorkoutType.run,
    targetDistanceMeters: 4000,
    note: 'Enfoque del día: estabilidad y ROTACIÓN para básquet. Corre primero '
        'y deja 3 min de respiración antes del core.',
    exercises: [
      Exercise(
        id: 'jue-mcgill-curlup',
        name: 'McGill curl-up',
        muscleGroup: 'Core anterior',
        sets: 3,
        reps: '10',
        restSeconds: 45,
        steps: [
          'Boca arriba, una rodilla flexionada y la otra estirada, manos bajo el lumbar para respetar su curva.',
          'Despega la cabeza y los omóplatos del suelo unos 5 cm, sin encogerte.',
          'Mantén 10 segundos, respirando; el cuello no tira de la cabeza.',
          'Baja lento y repite. Cambia la pierna flexionada a mitad de serie.',
          'Nunca dejes que el lumbar se aplane contra el suelo.',
        ],
        cue: 'Es un gesto pequeño: si parece un crunch abdominal, está mal.',
        basketballTransfer:
            'Activa el recto abdominal sin castigar el disco, la base para frenar en seco tras un sprint.',
        source: 'Dr. Stuart McGill (Big 3)',
        easier: '5 repeticiones de 5 s.',
        harder: '15 repeticiones de 10 s con brazos cruzados al pecho.',
      ),
      Exercise(
        id: 'jue-side-plank',
        name: 'Plancha lateral',
        muscleGroup: 'Core lateral',
        sets: 3,
        reps: '30 s por lado',
        restSeconds: 40,
        steps: [
          'De lado, codo bajo el hombro, pies uno delante del otro.',
          'Eleva la cadera hasta formar una línea recta; no dejes caer la pelvis.',
          'Empuja el suelo con el antebrazo y mantén el hombro lejos de la oreja.',
          'Mantén 30 s respirando; cambia de lado.',
          'Si aparece dolor en el hombro, apoya la rodilla de abajo.',
        ],
        cue: 'Cadera alta y glúteo activo: la plancha lateral es un ejercicio de cadera, no solo de abdomen.',
        basketballTransfer:
            'Estabiliza el tronco en los desplazamientos laterales defensivos y en el primer paso cruzado.',
        source: 'Dr. Stuart McGill (Big 3)',
        easier: 'Rodilla apoyada y 20 s.',
        harder: 'Pierna superior elevada o 45 s.',
      ),
      Exercise(
        id: 'jue-deadbug',
        name: 'Dead bug',
        muscleGroup: 'Core / Coordinación',
        sets: 3,
        reps: '8 por lado',
        restSeconds: 40,
        steps: [
          'Boca arriba, brazos al techo y rodillas a 90° sobre la cadera.',
          'Presiona el lumbar contra la colchoneta y mantenlo ahí todo el ejercicio.',
          'Extiende despacio el brazo derecho por encima de la cabeza y la pierna izquierda hacia delante.',
          'Vuelve al centro en 3 segundos y repite al lado contrario.',
          'Si el lumbar se despega, acorta el recorrido de la pierna.',
        ],
        cue: 'La espalda baja no se mueve ni un milímetro: ese es el ejercicio.',
        basketballTransfer:
            'Coordinación contralateral, la misma que usa el cuerpo al correr y botar a la vez.',
        source: 'EXOS / fisioterapia deportiva',
        easier: 'Solo piernas, brazos quietos.',
        harder: 'Extiende brazo y pierna completamente y añade pausa de 2 s.',
      ),
      Exercise(
        id: 'jue-hollow',
        name: 'Hollow hold',
        muscleGroup: 'Core anterior',
        sets: 3,
        reps: '30 s',
        restSeconds: 40,
        steps: [
          'Boca arriba, brazos por encima de la cabeza, piernas juntas y estiradas.',
          'Aplana el lumbar contra la colchoneta y elévelo ligeramente.',
          'Despega hombros y piernas del suelo lo justo para mantener la curva.',
          'Aguanta 30 s con respiración corta y constante.',
          'Baja controlado: no te dejes caer.',
        ],
        cue: 'Menos altura y más tensión: el objetivo es la rigidez, no tocar el techo.',
        basketballTransfer:
            'Rigidez anterior que transfiere la fuerza de las piernas al tiro en suspensión.',
        source: 'Gimnasia / McGill',
        easier: 'Rodillas a 90°.',
        harder: 'Piernas estiradas y brazos más cerca de las orejas.',
      ),
      Exercise(
        id: 'jue-birddog-rot',
        name: 'Bird dog con rotación',
        muscleGroup: 'Core / Rotación',
        sets: 3,
        reps: '8 por lado',
        restSeconds: 45,
        steps: [
          'En cuadrupedia, extiende brazo derecho y pierna izquierda.',
          'Sin perder la línea de la cadera, lleva el codo derecho hacia la rodilla izquierda por debajo del cuerpo.',
          'Redondea ligeramente la espalda alta al cerrar y aprieta el abdomen 2 segundos.',
          'Vuelve a extender completamente y repite.',
          'Completa 8 por lado manteniendo la cadera estable.',
        ],
        cue: 'La rotación ocurre en la espalda alta; la pelvis no se balancea.',
        basketballTransfer:
            'Rotación controlada del tronco, base del pase con una mano y del tiro tras bote.',
        source: 'Dr. Stuart McGill + P3',
        easier: 'Sin rotación: solo tocar el codo con la rodilla.',
        harder: 'Añade una pausa de 2 s en la extensión completa.',
      ),
      Exercise(
        id: 'jue-bicycle',
        name: 'Crunch bicicleta lento',
        muscleGroup: 'Oblicuos',
        sets: 3,
        reps: '20 (10 por lado)',
        restSeconds: 40,
        steps: [
          'Boca arriba, manos suaves en las sienes (nunca tirar del cuello), piernas elevadas con rodillas a 90°.',
          'Lleva el codo derecho hacia la rodilla izquierda mientras extiendes la pierna derecha.',
          'Gira desde las costillas, no desde los hombros, y mantén 1 segundo.',
          'Alterna al otro lado con ritmo lento: 2 segundos por repetición.',
          'El lumbar permanece pegado a la colchoneta.',
        ],
        cue: 'Lento y con rotación real: rápido solo mueve el cuello.',
        basketballTransfer:
            'Oblicuos fuertes para girar el torso en el tiro con fadeaway y en el pase cruzado.',
        source: 'Entrenamiento de core rotacional',
        easier: 'Codos sin tocar rodilla, solo intención.',
        harder: 'Pausa de 2 s en cada giro y pierna extendida a 30°.',
      ),
      Exercise(
        id: 'jue-thread-needle',
        name: 'Plancha lateral con rotación (thread the needle)',
        muscleGroup: 'Core / Rotación torácica',
        sets: 3,
        reps: '8 por lado',
        restSeconds: 45,
        steps: [
          'Plancha lateral sobre el codo derecho, pies apilados.',
          'Eleva el brazo izquierdo hacia el techo y abre el pecho.',
          'Pasa el brazo izquierdo por debajo del cuerpo, rotando la espalda alta, sin que la cadera caiga.',
          'Vuelve a abrir y repite 8 veces; cambia de lado.',
          'Respira: exhala al pasar el brazo por debajo.',
        ],
        cue: 'La cadera se queda alta y quieta; solo gira la caja torácica.',
        basketballTransfer:
            'Movilidad torácica activa: más rango de giro en el tiro sin compensar con el lumbar.',
        source: 'Fisioterapia deportiva / EXOS',
        easier: 'Sin rotación: solo elevar el brazo.',
        harder: 'Pausa de 2 s en cada posición y pies juntos.',
      ),
      Exercise(
        id: 'jue-pallof',
        name: 'Anti-rotación isométrica con toalla',
        muscleGroup: 'Core anti-rotación',
        sets: 3,
        reps: '20 s por lado',
        restSeconds: 35,
        steps: [
          'De rodillas o de pie, sujeta una toalla con las dos manos frente al pecho.',
          'Una mano tira de la toalla hacia un lado mientras el tronco resiste sin girar.',
          'Aprieta glúteos y abdomen; los hombros quedan cuadrados al frente.',
          'Mantén 20 s y cambia de dirección.',
          'La fuerza se aplica de forma progresiva, no de golpe.',
        ],
        cue: 'Si el torso gira aunque sea 5°, baja la fuerza.',
        basketballTransfer:
            'Resistir la rotación es lo que permite frenar un cambio de dirección sin perder el equilibrio.',
        source: 'Dr. Stuart McGill (anti-rotación)',
        easier: '15 s al 50 %.',
        harder: '25 s al 80 % de pie, con una pierna adelantada.',
      ),
    ],
  ),

  // ──────────────────────────────────────────────────────────── VIERNES ──
  RoutineDay(
    weekday: 5,
    title: 'Bicicleta 12 km',
    type: WorkoutType.bike,
    targetDistanceMeters: 12000,
    note: 'Si el lunes o el miércoles notaste las piernas cargadas, baja el ritmo '
        'pero no la distancia: hoy el objetivo es mover sangre, no competir.',
  ),

  // ───────────────────────────────────────────────────────────── SÁBADO ──
  RoutineDay(
    weekday: 6,
    title: 'Bicicleta 12 km',
    type: WorkoutType.bike,
    targetDistanceMeters: 12000,
    note: 'Última salida de la semana. Termina con 5 min de estiramiento de '
        'cuádriceps, psoas y gemelos.',
  ),

  // ──────────────────────────────────────────────────────────── DOMINGO ──
  RoutineDay(
    weekday: 7,
    title: 'Descanso / Recuperación activa',
    type: WorkoutType.rest,
    targetDistanceMeters: 0,
    isRestDay: true,
    note: '20-30 min de caminata suave, movilidad de tobillo y cadera, y '
        'estiramientos. Duerme 8 h: la adaptación ocurre hoy, no en la bici.',
  ),
];
