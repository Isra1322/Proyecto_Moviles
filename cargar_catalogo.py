import xmlrpc.client

# Configuración de conexión Odoo
URL = 'http://localhost:8069'
DB = 'ecommerce_moviles'
USER = 'isra@gmail.com'
PASS = 'root'  # Si tu clave de Odoo web es distinta, cámbiala aquí

# 1. Autenticación
common = xmlrpc.client.ServerProxy(f'{URL}/xmlrpc/2/common')
uid = common.authenticate(DB, USER, PASS, {})
models = xmlrpc.client.ServerProxy(f'{URL}/xmlrpc/2/object')

print(f"Conectado exitosamente. UID: {uid}")

if not uid:
    print("Error: No se pudo autenticar. Verifica tu usuario y contraseña.")
    exit()

# Obtener IDs de las categorías creadas
def get_category_id(cat_name):
    cat_ids = models.execute_kw(DB, uid, PASS, 'product.category', 'search', [[['name', '=', cat_name]]])
    return cat_ids[0] if cat_ids else False

# Imagen 1x1 PNG transparente inicial
PLACEHOLDER_IMAGE = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="

# Catálogo a insertar (4 categorías x 10 productos)
catalog = {
    "Smartphones": [
        ("iPhone 15 Pro Max", 1250.00),
        ("Samsung Galaxy S24 Ultra", 1200.00),
        ("Google Pixel 8 Pro", 890.00),
        ("Xiaomi 14 Ultra", 1100.00),
        ("Samsung Galaxy A55 5G", 380.00),
        ("iPhone 13", 599.00),
        ("OnePlus 12", 799.00),
        ("Motorola Edge 50 Pro", 550.00),
        ("POCO F6 Pro", 470.00),
        ("Honor Magic 6 Pro", 950.00)
    ],
    "Monitores": [
        ("Monitor Gamer Samsung Odyssey G5 27\"", 280.00),
        ("Monitor LG UltraGear 24\"", 160.00),
        ("Monitor Dell UltraSharp 27\" 4K", 520.00),
        ("Monitor ASUS TUF Gaming 32\"", 340.00),
        ("Monitor Xiaomi Mi Desktop 27\"", 140.00),
        ("Monitor BenQ ZOWIE XL2411K 24\"", 210.00),
        ("Monitor Curvo MSI Optix 34\" Ultrawide", 450.00),
        ("Monitor ViewSonic 24\" Oficina", 115.00),
        ("Monitor Philips Evnia 27\"", 230.00),
        ("Monitor Gigabyte M28U 28\" 4K", 580.00)
    ],
    "Audio y Auriculares": [
        ("Sony WH-1000XM5", 360.00),
        ("AirPods Pro (2da Gen)", 240.00),
        ("Samsung Galaxy Buds2 Pro", 140.00),
        ("JBL Flip 6", 110.00),
        ("Bose QuietComfort 45", 280.00),
        ("Logitech G733 Lightspeed", 130.00),
        ("HyperX Cloud II", 75.00),
        ("Anker Soundcore Space Q45", 95.00),
        ("Sennheiser Momentum 4", 310.00),
        ("Echo Dot 5ta Gen", 50.00)
    ],
    "Accesorios y Periféricos": [
        ("Mouse Logitech MX Master 3S", 99.00),
        ("Teclado Mecánico Keychron K2", 85.00),
        ("Mouse Gamer Razer DeathAdder V3", 65.00),
        ("Teclado Logitech MX Keys S", 110.00),
        ("Webcam Logitech Brio 4K", 160.00),
        ("Disco Externo Kingston XS1000 1TB SSD", 80.00),
        ("Hub USB-C Ugreen Revodok 7 en 1", 35.00),
        ("Mousepad Gamer SteelSeries QcK Heavy XXL", 30.00),
        ("Cargador Rápido Baseus GaN 65W", 32.00),
        ("Micrófono Blue Yeti USB", 115.00)
    ]
}

# Obtener almacén principal para asignar stock
location_ids = models.execute_kw(DB, uid, PASS, 'stock.location', 'search', [[['usage', '=', 'internal']]], {'limit': 1})
location_id = location_ids[0] if location_ids else False

for category_name, products in catalog.items():
    cat_id = get_category_id(category_name)
    if not cat_id:
        cat_id = models.execute_kw(DB, uid, PASS, 'product.category', 'create', [{'name': category_name}])
        print(f"Categoría creada: {category_name} (ID: {cat_id})")

    for prod_name, price in products:
        tmpl_id = models.execute_kw(DB, uid, PASS, 'product.template', 'create', [{
            'name': prod_name,
            'list_price': price,
            'categ_id': cat_id,
            'sale_ok': True,
            'purchase_ok': True,
            'is_storable': True,
            'image_128': PLACEHOLDER_IMAGE
        }])

        # Asignar 50 unidades de stock de forma segura
        prod_variants = models.execute_kw(DB, uid, PASS, 'product.product', 'search', [[['product_tmpl_id', '=', tmpl_id]]])
        if prod_variants and location_id:
            try:
                models.execute_kw(DB, uid, PASS, 'stock.quant', 'create', [{
                    'product_id': prod_variants[0],
                    'location_id': location_id,
                    'quantity': 50.0,
                }])
            except Exception:
                try:
                    models.execute_kw(DB, uid, PASS, 'stock.quant', 'create', [{
                        'product_id': prod_variants[0],
                        'location_id': location_id,
                        'inventory_quantity': 50.0,
                    }])
                except Exception:
                    pass

        print(f"Creado: {prod_name} - ${price}")

print("¡Importación masiva completada con éxito!")