# -*- coding: utf-8 -*-
import xmlrpc.client

# Configuración de conexión Odoo
URL = 'http://localhost:8069'
DB = 'ecommerce_moviles'
USER = 'isra@gmail.com'
PASS = 'root'  # Tu contraseña de conexión XML-RPC

# 1. Autenticación
common = xmlrpc.client.ServerProxy(f'{URL}/xmlrpc/2/common')
uid = common.authenticate(DB, USER, PASS, {})
models = xmlrpc.client.ServerProxy(f'{URL}/xmlrpc/2/object')

if not uid:
    print("Error: No se pudo autenticar en Odoo. Revisa las credenciales.")
    exit()

print(f"Conexión exitosa a Odoo. UID: {uid}")

# Diccionario con especificaciones técnicas detalladas y reales
product_descriptions = {
    # --- Smartphones ---
    "iPhone 15 Pro Max": (
        "Pantalla Super Retina XDR OLED 6.7\" 120Hz ProMotion. Chip A17 Pro (3nm). "
        "Cámara principal de 48 MP con teleobjetivo 5x tipo periscopio. Chasis de titanio de grado aeroespacial. "
        "Conector USB-C compatible con USB 3. Batería de hasta 29h de reproducción de video."
    ),
    "iPhone 15 Pro": (
        "Pantalla Super Retina XDR OLED 6.1\" 120Hz ProMotion con Isla Dinámica. Chip A17 Pro fabricado en 3nm. "
        "Cámara principal de 48 MP con múltiples distancias focales y teleobjetivo 3x. Botón de Acción personalizable "
        "y chasis de titanio liviano y resistente. Puerto USB-C con soporte USB 3."
    ),
    "Samsung Galaxy S24 Ultra": (
        "Pantalla Dynamic AMOLED 2X 6.8\" QHD+ plana con Gorilla Armor antirreflejos. "
        "Snapdragon 8 Gen 3 for Galaxy. Cámara cuádruple de 200 MP con Space Zoom 100x. "
        "S-Pen integrado con funciones Galaxy AI. Marco de titanio y batería de 5000 mAh con carga de 45W."
    ),
    "Google Pixel 8 Pro": (
        "Pantalla Super Actua OLED 6.7\" LTPO a 120Hz. Procesador Google Tensor G3 con coprocesador Titan M2. "
        "Cámara triple de 50 MP con IA avanzada (Magic Editor, Best Take). Sensor de temperatura corporal. "
        "Batería de 5050 mAh y 7 años garantizados de actualizaciones de Android."
    ),
    "Xiaomi 14 Ultra": (
        "Pantalla AMOLED WQHD+ 6.73\" a 120Hz con 3000 nits de brillo pico. Snapdragon 8 Gen 3. "
        "Óptica cuádruple Leica de 50 MP con sensor principal LYT-900 de 1 pulgada y apertura variable continua. "
        "Grabación de video 8K. Batería de 5000 mAh con carga HyperCharge de 90W y 80W inalámbrica."
    ),
    "Samsung Galaxy A55 5G": (
        "Pantalla Super AMOLED FHD+ 6.6\" a 120Hz con Vision Booster. Procesador Exynos 1480 con GPU AMD Xclipse. "
        "Cámara principal de 50 MP con OIS y video nocturno mejorado. Certificación IP67 contra agua y polvo. "
        "Batería de 5000 mAh con carga rápida de 25W."
    ),
    "iPhone 13": (
        "Pantalla Super Retina XDR OLED de 6.1\". Chip A15 Bionic con CPU de 6 núcleos y GPU de 4 núcleos. "
        "Sistema de doble cámara de 12 MP con estabilización óptica por desplazamiento de sensor y Modo Cine a 1080p. "
        "Frente de Ceramic Shield resistente y compatibilidad total con accesorios MagSafe."
    ),
    "OnePlus 12": (
        "Pantalla 2K ProXDR AMOLED 6.82\" a 120Hz con brillo récord de 4500 nits. Snapdragon 8 Gen 3. "
        "Cámara Hasselblad de 4ta generación (50 MP + 64 MP periscopio 3x). "
        "Batería masiva de 5400 mAh con carga ultrarrápida SUPERVOOC de 80W y AIRVOOC inalámbrica de 50W."
    ),
    "Motorola Edge 50 Pro": (
        "Pantalla curva pOLED 6.7\" Super HD (1220p) a 144Hz con validación de color Pantone. "
        "Procesador Snapdragon 7 Gen 3. Cámara de 50 MP con apertura f/1.4 y teleobjetivo 3x. "
        "Carga TurboPower de 125W (100% en 18 minutos) y resistencia al agua IP68 con acabado en cuero vegano."
    ),
    "POCO F6 Pro": (
        "Pantalla AMOLED Flow WQHD+ 6.67\" a 120Hz con 4000 nits pico. Procesador insignia Snapdragon 8 Gen 2. "
        "Cámara triple de 50 MP con sensor Light Fusion 800 y estabilización óptica (OIS). "
        "Tecnología de refrigeración LiquidCool 4.0 y carga rápida HyperCharge de 120W (cargador incluido)."
    ),
    "Honor Magic 6 Pro": (
        "Pantalla curva OLED LTPO 6.8\" con atenuación PWM a 4320Hz para cero fatiga visual. Snapdragon 8 Gen 3. "
        "Teleobjetivo periscópico de 180 MP y sensor principal Falcon de apertura variable f/1.4-f/2.0. "
        "Batería de silicio-carbono de 5600 mAh de 2da generación resistente a temperaturas extremas."
    ),

    # --- Monitores ---
    "Monitor Gamer Samsung Odyssey G5 27\"": (
        "Panel VA curvo 1000R de 27 pulgadas con resolución QHD (2560x1440). Tasa de refresco de 165Hz y "
        "tiempo de respuesta de 1ms (MPRT). Compatible con AMD FreeSync Premium y soporte HDR10. "
        "Conectividad DisplayPort 1.4 y HDMI 2.0."
    ),
    "Monitor LG UltraGear 24\"": (
        "Panel IPS Full HD (1920x1080) de 23.8\" con tiempo de respuesta de 1ms MBR. Frecuencia de 144Hz para "
        "fluidez competitiva. Soporte para AMD FreeSync y tecnología Dynamic Action Sync para minimizar el input lag. "
        "Diseño prácticamente sin bordes en 3 lados."
    ),
    "Monitor Dell UltraSharp 27\" 4K": (
        "Panel IPS Black de 27 pulgadas con resolución 4K UHD (3840x2160) y relación de contraste 2000:1. "
        "Cobertura de color del 98% DCI-P3 y 100% sRGB con calibración de fábrica Delta E < 2. "
        "Hub USB-C integrado con suministro de energía Power Delivery de hasta 90W y puerto Ethernet RJ-45."
    ),
    "Monitor ASUS TUF Gaming 32\"": (
        "Panel Fast IPS de 31.5\" con resolución WQHD (2560x1440). Frecuencia extrema de 170Hz (overclock) y 1ms GTG. "
        "Certificación VESA DisplayHDR 400 y cobertura sRGB del 130%. Tecnología ASUS Extreme Low Motion Blur Sync "
        "(ELMB Sync) compatible con G-SYNC y FreeSync."
    ),
    "Monitor Xiaomi Mi Desktop 27\"": (
        "Panel IPS Full HD (1920x1080) con ángulo de visión amplio de 178°. Tasa de refresco de 75Hz. "
        "Gama de color 100% sRGB con tecnología Low Blue Light certificada por TÜV Rheinland contra la luz azul. "
        "Cuerpo ultradelgado de 7.5 mm y base metálica minimalista ajustable en inclinación."
    ),
    "Monitor BenQ ZOWIE XL2411K 24\"": (
        "Panel TN optimizado para deportes electrónicos (Esports) de 24 pulgadas Full HD a 144Hz. "
        "Tecnología exclusiva DyAc (Dynamic Accuracy) para eliminar el desenfoque en movimientos rápidos y disparos. "
        "Funciones Black eQualizer y Color Vibrance para detectar enemigos en sombras. Base compacta orientable."
    ),
    "Monitor Curvo MSI Optix 34\" Ultrawide": (
        "Panel VA panorámico Ultra-Wide QHD (3440x1440) en relación de aspecto 21:9 con curvatura 1500R. "
        "Frecuencia de actualización de 144Hz y respuesta de 1ms. Cobertura del 115% sRGB y tecnología Night Vision. "
        "Permite visualización dividida Picture-by-Picture (PbP) para multitarea productiva."
    ),
    "Monitor ViewSonic 24\" Oficina": (
        "Panel SuperClear IPS de 24 pulgadas Full HD (1080p). Tasa de actualización de 75Hz y tecnología Flicker-Free "
        "con filtro de luz azul para jornadas laborales prolongadas. Altavoces estéreo duales integrados. "
        "Entradas HDMI, DisplayPort y VGA para máxima compatibilidad con laptops y PCs antiguas."
    ),
    "Monitor Philips Evnia 27\"": (
        "Panel Fast IPS de 27 pulgadas QHD (2560x1440) con tasa de refresco ultrafluida de 180Hz y 0.5ms SmartImage Game. "
        "Certificación HDR400 para negros profundos y blancos nítidos. Cobertura NTSC 111% y sRGB 130%. "
        "Soporte ergonómico con ajuste completo de altura, giro, pivote e inclinación."
    ),
    "Monitor Gigabyte M28U 28\" 4K": (
        "Panel Super Speed IPS de 28 pulgadas con resolución 4K (3840x2160) y 144Hz de refresco (1ms GTG). "
        "Dos puertos HDMI 2.1 con ancho de banda total para consolas PS5 y Xbox Series X a 4K 120Hz. "
        "Botón KVM integrado para controlar dos PCs diferentes con un solo teclado y ratón."
    ),

    # --- Audio y Auriculares ---
    "Sony WH-1000XM5": (
        "Auriculares Over-Ear con cancelación activa de ruido líder del sector gracias a sus 8 micrófonos y 2 procesadores V1/QN1. "
        "Controladores de 30 mm de fibra de carbono. Compatibles con audio Hi-Res y códec LDAC. "
        "Hasta 30 horas de autonomía con carga rápida (3 horas de batería con 3 minutos de carga). Conexión multipunto."
    ),
    "AirPods Pro (2da Gen)": (
        "Auriculares True Wireless con chip H2 de Apple y cancelación activa de ruido 2x superior. "
        "Modo Ambiente Adaptativo y Audio Espacial personalizado con seguimiento dinámico de la cabeza. "
        "Estuche MagSafe con altavoz integrado para búsqueda precisa mediante app Buscar y puerto USB-C."
    ),
    "Samsung Galaxy Buds2 Pro": (
        "Auriculares intrauditivos inalámbricos con cancelación activa de ruido inteligente (ANC) de 3 micrófonos SNR altos. "
        "Audio Hi-Fi de 24 bits sin pérdidas y sonido envolvente 360 con Dolby Atmos. "
        "Diseño compacto y ergonómico un 15% más pequeño que su predecesor. Resistencia al agua IPX7."
    ),
    "JBL Flip 6": (
        "Altavoz portátil Bluetooth con sistema de altavoces de 2 vías: subwoofer tipo pista de carreras, tweeter independiente "
        "y radiadores pasivos duales. Potencia de 30W RMS. Certificación IP67 resistente al agua y al polvo. "
        "Hasta 12 horas de música continua y función PartyBoost para vincular varios altavoces."
    ),
    "Bose QuietComfort 45": (
        "Auriculares inalámbricos premium con almohadillas afelpadas de cuero sintético y cancelación de ruido acústica Acoustic Noise Cancelling. "
        "Modos Quiet (cancelación total) y Aware (atención al entorno). Arquitectura acústica TriPort patentada. "
        "Hasta 22 horas de batería por carga con puerto USB-C."
    ),
    "Logitech G733 Lightspeed": (
        "Auriculares inalámbricos para gaming con diadema de suspensión reversible y transductores PRO-G de 40 mm. "
        "Tecnología inalámbrica LIGHTSPEED con alcance de hasta 20 metros y 29 horas de autonomía. "
        "Iluminación RGB LIGHTSYNC frontal personalizable y micrófono extraíble con filtros Blue VO!CE."
    ),
    "HyperX Cloud II": (
        "Auriculares para gaming legendarios con estructura de aluminio resistente y almohadillas de espuma viscoelástica con memoria. "
        "Transductores de neodimio de 53 mm y caja de control de audio USB avanzada con sonido envolvente virtual 7.1. "
        "Micrófono desmontable con cancelación de ruido pasiva certificado por Discord y TeamSpeak."
    ),
    "Anker Soundcore Space Q45": (
        "Auriculares con cancelación de ruido activa adaptativa que reduce el ruido exterior hasta en un 98%. "
        "Drivers de 40 mm con diafragmas de doble capa de seda y cerámica con certificación Hi-Res Wireless y LDAC. "
        "Impresionante autonomía de hasta 50 horas con ANC encendido (65 horas en modo normal)."
    ),
    "Sennheiser Momentum 4": (
        "Auriculares audiófilos inalámbricos con transductores de 42 mm inspirados en la ingeniería de sonido acústico de Sennheiser. "
        "Cancelación de ruido adaptativa híbrida de última generación. "
        "Batería líder en la industria de hasta 60 horas de reproducción continua con una sola carga. Compatibilidad con códecs aptX Adaptive."
    ),
    "Echo Dot 5ta Gen": (
        "Altavoz inteligente con asistente de voz Alexa y arquitectura acústica mejorada para voces más nítidas y graves profundos. "
        "Sensor de temperatura incorporado para automatizaciones del hogar inteligente. "
        "Controles táctiles para pausar música y silenciar micrófonos para proteger la privacidad."
    ),

    # --- Laptops y Computadoras ---
    "Apple MacBook Pro 14\" M3": (
        "Pantalla Liquid Retina XDR de 14.2\" con ProMotion 120Hz y brillo sostenido de 1000 nits. Chip Apple M3 con "
        "CPU de 8 núcleos y GPU de 10 núcleos con trazado de rayos por hardware. 8GB de memoria unificada y 512GB SSD. "
        "Hasta 22 horas de autonomía de batería, cámara FaceTime HD 1080p y sistema de 6 altavoces con audio espacial."
    ),
    "MacBook Air M2": (
        "Pantalla Liquid Retina de 13.6\" con 500 nits de brillo. Chip Apple M2 con CPU de 8 núcleos y GPU de 8 núcleos. "
        "Diseño ultradelgado sin ventilador de 11.3 mm en aluminio 100% reciclado. Teclado Magic Keyboard retroiluminado "
        "con Touch ID. Hasta 18 horas de batería y puerto de carga MagSafe 3."
    ),
    "ASUS ROG Zephyrus G14": (
        "Pantalla ROG Nebula OLED 14\" 3K (2880x1800) a 120Hz con tiempo de respuesta de 0.2ms. Procesador AMD Ryzen 9 8945HS "
        "con Ryzen AI. Gráficos NVIDIA GeForce RTX 4060 con 8GB GDDR6. Chasis unibody de aluminio mecanizado CNC con "
        "iluminación Slash Lighting y refrigeración con metal líquido."
    ),
    "Laptop Lenovo Legion 5": (
        "Pantalla IPS WQXGA (2560x1600) de 16\" a 165Hz con 100% sRGB y soporte G-SYNC. Procesador AMD Ryzen 7 7745HX. "
        "Tarjeta gráfica NVIDIA GeForce RTX 4060 8GB GDDR6 de 140W TGP. Sistema térmico Legion Coldfront 5.0 y "
        "teclado Legion TrueStrike con retroiluminación RGB de 4 zonas."
    ),
    "Lenovo ThinkPad E14": (
        "Pantalla IPS de 14\" WUXGA (1920x1200) antirreflejos. Procesador Intel Core i7 de 13ra generación con gráficos Iris Xe. "
        "Construcción de grado militar MIL-STD-810H resistente a caídas y salpicaduras. Teclado legendario ergonómico con TrackPoint "
        "rojo y obturador físico ThinkShutter para la cámara web."
    ),
    "Dell XPS 13": (
        "Pantalla InfinityEdge FHD+ de 13.4\" con bordes casi invisibles y 500 nits de brillo. Procesador Intel Core Ultra 7 "
        "con NPU dedicada para inteligencia artificial. Chasis de aluminio mecanizado CNC y reposamanos de vidrio con panel "
        "táctil háptico invisible y fila de funciones táctiles capacitivas."
    ),
    "HP Pavilion 15": (
        "Pantalla IPS de 15.6\" Full HD con microbordes y tecnología antiparpadeo. Procesador Intel Core i5 de 12da generación. "
        "16GB de memoria RAM DDR4 y almacenamiento SSD PCIe NVMe de 512GB. Sistema de audio de alta fidelidad B&O (Bang & Olufsen) "
        "y batería de larga duración con carga rápida HP Fast Charge."
    ),
    "MSI Katana 15": (
        "Pantalla IPS de 15.6\" Full HD a 144Hz. Procesador Intel Core i7-13620H de 10 núcleos. Tarjeta gráfica dedicada "
        "NVIDIA GeForce RTX 4060 con arquitectura Ada Lovelace y DLSS 3. Teclado retroiluminado RGB de 4 zonas con teclas WASD "
        "resaltadas y tecnología Cooler Boost 5 de doble ventilador."
    ),
    "Acer Nitro V 15": (
        "Pantalla IPS de 15.6\" Full HD a 144Hz con formato 16:9. Procesador Intel Core i5-13420H y gráficos NVIDIA GeForce "
        "RTX 4050 6GB GDDR6. Audio envolvente DTS:X Ultra con altavoces duales. Conectividad ultrarrápida con Wi-Fi 6 y "
        "puerto Thunderbolt 4 multifunción."
    ),
    "ASUS ZenBook 14 OLED": (
        "Pantalla táctil ASUS Lumina OLED 14\" 3K (2880x1800) a 120Hz con validación PANTONE y 100% DCI-P3. Procesador "
        "Intel Core Ultra 7 155H con motor de IA Intel AI Boost. Chasis ultraliviano de 1.2 kg con perfil de 14.9 mm y "
        "batería de 75Wh con hasta 15 horas de uso."
    ),

    # --- Periféricos y Accesorios ---
    "Mouse Logitech MX Master 3S": (
        "Sensor óptico Darkfield de alta precisión de 8000 DPI con seguimiento sobre cualquier superficie, incluso vidrio. "
        "Clics silenciosos Quiet Clicks con reducción del 90% del ruido. Rueda de desplazamiento electromagnética MagSpeed "
        "capaz de desplazarse hasta 1000 líneas por segundo. Conectividad Bluetooth y receptor Logi Bolt con Flow multidispositivo."
    ),
    "Teclado Mecánico Keychron K2": (
        "Teclado mecánico inalámbrico al 75% con 84 teclas. Interruptores mecánicos Gateron G Pro intercambiables en caliente (Hot-swappable). "
        "Conectividad dual por Bluetooth 5.1 (hasta 3 dispositivos) y cable USB-C desmontable. Compatible al 100% con macOS y Windows "
        "con teclas dedicadas para cada sistema. Batería recargable de 4000 mAh."
    ),
    "Mouse Gamer Razer DeathAdder V3": (
        "Sensor óptico Razer Focus Pro de 30.000 DPI con 99.8% de precisión de resolución. Switches ópticos para ratón Razer "
        "de 3ra generación con ciclo de vida de 90 millones de clics y sin fallos por rebote. Peso ultraligero de solo 59 gramos "
        "sin perforaciones exteriores. Cable flexible Razer Speedflex y tasa de sondeo real de 8000Hz."
    ),
    "Teclado Logitech MX Keys S": (
        "Teclado inalámbrico avanzado de bajo perfil con teclas cóncavas esféricas Perfect Stroke adaptadas a la forma de las yemas. "
        "Retroiluminación inteligente con sensores de proximidad de manos que ajusta el brillo automáticamente según la luz ambiente. "
        "Acciones inteligentes Smart Actions programables mediante la app Logi Options+ y carga rápida por USB-C."
    ),
    "Webcam Logitech Brio 4K": (
        "Cámara web profesional con resolución Ultra HD 4K a 30 fps o 1080p a 60 fps. Sensor de imagen avanzado con tecnología "
        "RightLight 3 y HDR para destacar en condiciones de poca luz o luz solar directa. Reconocimiento facial por infrarrojos compatible "
        "con Windows Hello para inicio de sesión seguro. Campo visual ajustable a 65°, 78° y 90°."
    ),
    "Disco Externo Kingston XS1000 1TB SSD": (
        "Unidad de estado sólido externa ultracompacta de bolsillo (pesa apenas 28.7 gramos). Interfaz USB 3.2 Gen 2 con velocidades "
        "de lectura de hasta 1050 MB/s y escritura de hasta 1000 MB/s. Compatible con PC, Mac, tablets y consolas de videojuegos. "
        "Carcasa metálica resistente a vibraciones y golpes con cable USB-C a USB-A incluido."
    ),
    "Hub USB-C Ugreen Revodok 7 en 1": (
        "Adaptador multipuerto USB-C con salida HDMI 4K a 60Hz nítida y fluida. Puerto de carga USB-C Power Delivery de 100W "
        "para alimentar portátiles a máxima velocidad. Dos puertos USB-A 3.0 de 5Gbps, un puerto USB-C de datos y ranuras para "
        "tarjetas SD y microSD con lectura simultánea. Carcasa de aleación de aluminio para eficiente disipación térmica."
    ),
    "Mousepad Gamer SteelSeries QcK Heavy XXL": (
        "Alfombrilla de ratón de tamaño extra grande (900 mm x 400 mm) con base gruesa de 4 mm de goma antideslizante que elimina "
        "movimientos no deseados y amortigua la muñeca. Tejido de microfibra de alta densidad optimizado para sensores ópticos y láser. "
        "Bordes cosidos de perfil bajo contra el desgaste y deshilachado."
    ),
    "Cargador Rápido Baseus GaN 65W": (
        "Cargador de pared con tecnología de nitruro de galio (GaN 5ta Gen) que reduce el tamaño un 50% con menor emisión de calor. "
        "Tres puertos de salida: 2x USB-C y 1x USB-A con soporte para protocolos PD 3.0, QC 4+, PPS y AFC. Permite cargar una laptop "
        "de 65W y dos teléfonos inteligentes simultáneamente con distribución inteligente BPS II."
    ),
    "Micrófono Blue Yeti USB": (
        "Micrófono de condensador profesional con matriz patentada de tres cápsulas de condensador. Cuatro patrones de captación seleccionables: "
        "cardioide para streaming/podcasts, bidireccional para entrevistas, omnidireccional para reuniones y estéreo para música. "
        "Controles integrados de ganancia, botón de silenciamiento instantáneo y salida de auriculares de latencia cero de 3.5 mm."
    ),
    "Camiseta Deportiva": (
        "Camiseta técnica de alto rendimiento confeccionada en tejido microperforado 100% poliéster transpirable con tecnología "
        "de secado rápido Dri-Fit. Costuras planas ergonómicas Flatlock para evitar roces y detalles reflectantes para entrenamientos "
        "nocturnos al aire libre."
    ),
    "Zapatillas deportivas": (
        "Calzado deportivo ergonómico con capellada de malla transpirable Engineered Mesh. Mediasuela con amortiguación de espuma reactiva "
        "EVA de doble densidad para absorción de impactos y retorno de energía. Suela exterior de caucho resistente a la abrasión con "
        "patrón de tracción multidireccional para running y entrenamiento."
    ),
}

# 2. Actualización de productos en Odoo
print("\nIniciando actualización de descripciones técnicas en Odoo...\n" + "=" * 60)
actualizados = 0
no_encontrados = []

for name, desc in product_descriptions.items():
    # Buscar producto por nombre exacto en product.template
    prod_ids = models.execute_kw(DB, uid, PASS, 'product.template', 'search', [[('name', '=', name)]])
    if not prod_ids:
        # Intentar búsqueda con ilike si no fue exacto
        prod_ids = models.execute_kw(DB, uid, PASS, 'product.template', 'search', [[('name', 'ilike', name)]])

    if prod_ids:
        for pid in prod_ids:
            models.execute_kw(DB, uid, PASS, 'product.template', 'write', [[pid], {
                'description_sale': desc,
                'description': desc,
            }])
            print(f"[OK] Actualizado (ID: {pid}): {name}")
            actualizados += 1
    else:
        print(f"[AVISO] No se encontró en Odoo: {name}")
        no_encontrados.append(name)

print("=" * 60)
print(f"Resumen: {actualizados} productos actualizados exitosamente.")
if no_encontrados:
    print(f"Productos no localizados ({len(no_encontrados)}): {', '.join(no_encontrados)}")
