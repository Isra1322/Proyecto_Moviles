# 🛒 E-Commerce Móvil con Odoo, .NET y Flutter

Instrucciones esenciales para ejecutar el proyecto (Backend, Frontend y Odoo) en tu máquina local.

## 1. Instalar y Configurar Odoo
1. Descarga e instala **Odoo Community** desde su página oficial: 
   👉 [https://www.odoo.com/page/download](https://www.odoo.com/page/download)
2. Al instalarlo, elige tu base de datos PostgreSQL y crea una con el nombre `ecommerce_moviles`.
3. Entra a Odoo (`http://localhost:8069`), instala los módulos de **Ventas** e **Inventario**, y crea algunos productos y un cliente.
4. **Muy importante:** Anota el **correo** y la **contraseña** con los que creaste tu usuario administrador de Odoo. Los usarás a continuación.

## 2. Configurar el Backend (.NET)
1. Abre el archivo:
   📄 `backend/ECommerce.WebApi/appsettings.json`
2. Busca la sección `OdooSettings` y coloca tus credenciales anotadas (deja la URL y el puerto como están):
   ```json
   "OdooSettings": {
     "Url": "http://localhost:8069",
     "Database": "ecommerce_moviles",
     "Username": "TU_CORREO_DE_ODOO",
     "Password": "TU_CONTRASEÑA_DE_ODOO",
     "TimeoutSeconds": 30
   }
Abre una terminal en la carpeta backend y ejecuta:

bash
dotnet run --project ECommerce.WebApi --urls "http://0.0.0.0:5124"
(Deja esta ventana abierta).

3. Instalar Tailscale y Configurar el Frontend (Flutter)
Para que tu celular físico se conecte a la API, necesitas Tailscale (una VPN gratuita).

Descarga e instala Tailscale en tu laptop y en tu celular.
👉 https://tailscale.com/download

Inicia sesión con la misma cuenta en ambos dispositivos.

En tu laptop, abre la aplicación de Tailscale y copia la dirección IP que te asigna (empieza con 100..., ej. 100.75.87.114).

Ve a Flutter y abre el archivo exacto:
📄 mobile/ecommerce_app/lib/core/constants/api_constants.dart

Busca la variable baseUrl y reemplaza la IP por la tuya (asegúrate de mantener el puerto :5124):

dart
class ApiConstants {
  // Pon aquí la IP que copiaste de Tailscale
  static const String baseUrl = 'http://100.75.87.114:5124'; 
  
  static const String products = '/api/Products';
  // ...
}
4. Ejecutar la App
Conecta tu celular por USB y activa la Depuración USB.

Asegúrate de tener Tailscale encendido en el celular.

Abre una terminal en mobile/ecommerce_app y ejecuta:

bash
flutter pub get
flutter run
