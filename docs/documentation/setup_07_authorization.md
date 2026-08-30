## Setup: Authorization

### Objetivo
Implementar una capa de autorización robusta, explícita y escalable utilizando la gema `pundit`. Establecer el modelo de datos basado en `User` → `Role` → `Permissions` definido en el ADR, eliminando por completo las comprobaciones condicionales duras (hardcoded) en el código y preparando el terreno para que, en un futuro, los permisos puedan gestionarse desde una interfaz administrativa sin necesidad de despliegues.

### Decisiones arquitectónicas

*   **Gema seleccionada (Pundit vs CanCanCan):** Se elige `pundit` porque se alinea perfectamente con la filosofía "Explicit over Magic". En lugar de un archivo centralizado gigante y difícil de testear (como `ability.rb`), Pundit utiliza clases Ruby planas (POROs) llamadas *Policies* (ej. `UserPolicy`). Esto favorece la mantenibilidad y facilita las pruebas unitarias aisladas.
*   **Cero hardcoding en vistas y controladores:** Queda estrictamente prohibido el uso de `if current_user.role == 'admin'` o `if current_user.admin?`. Toda comprobación de acceso se hará exclusivamente a través de Pundit (ej. `if policy(User).create?` en vistas y `authorize @user` en controladores).
*   **Controladores protegidos por defecto:** Así como en el Setup 6 forzamos la autenticación por defecto, en `ApplicationController` agregaremos un `after_action :verify_authorized`, excepto para el `SessionsController`. Esto asegura que un desarrollador futuro no pueda crear un endpoint vulnerable por simple omisión.
*   **Manejo de accesos denegados:** Capturaremos globalmente `Pundit::NotAuthorizedError` en el `ApplicationController` para redirigir al usuario educadamente al root (o al referer) con un mensaje de alerta estándar en el `flash[:alert]`, evitando caídas 500 o rastros de error.

### Modelado de datos

Rechazamos el uso de un `enum` simple para roles. La estructura en base de datos será:
1.  **`roles` (Tabla):** `id`, `name` (ej. 'Administrador', 'Editor'), `slug` (ej. 'admin').
2.  **`permissions` (Tabla):** `id`, `resource` (ej. 'User', 'Report'), `action` (ej. 'read', 'write', 'delete').
3.  **`role_permissions` (Tabla de unión):** `role_id`, `permission_id`.
4.  **`users` (Actualización):** Se agregará `belongs_to :role` (o `role_id`). 

*Nota temporal:* Como aún no llegamos al Setup 13 (Usuarios) donde crearemos la UI, para este setup solo crearemos las migraciones, los modelos y un *seed* inicial que inyecte el rol de "Super Admin" con acceso total.

### Estrategia en Base Policy (`ApplicationPolicy`)
Pundit funciona heredando de un `ApplicationPolicy`. En lugar de consultar la base de datos en cada policy (lo cual causaría N+1 queries), implementaremos un método en el modelo `User` (ej. `has_permission?(resource, action)`) que evalúe si su rol asociado cuenta con dicho permiso.
*   **Optimizacion futura:** Los permisos resueltos de un usuario se cargarán en memoria (memoization) o cache durante la petición actual para garantizar rendimiento máximo.

### Mantenibilidad y compatibilidad futura
Al estructurar la autorización a nivel de datos (tablas) en lugar de código (enums/constantes), logramos que la arquitectura sea agnóstica a la lógica de negocio temporal. Si en 3 años la UACH requiere un nuevo rol de "Auditor Financiero" con acceso solo de lectura a 4 catálogos específicos, se podrá crear desde la base de datos (o la UI futura) asociando los permisos correspondientes. Ningún controlador, modelo o vista (código Ruby) tendrá que ser modificado o redesplegado.

### Setup: Authorization

#### Objetivo
Implementar el motor de autorización basado en Pundit y un modelo de datos `Role` → `Permission`. Se elimina por diseño cualquier chequeo estático tipo `if current_user.admin?`, logrando una arquitectura "Secure by Default" donde cada controlador exige verificación explícita de permisos antes de renderizar o ejecutar acciones.

#### Decisiones arquitectónicas
*   **Explicit over Magic:** Pundit evalúa clases Ruby planas en lugar de DSLs complejos. Toda la lógica de "quién puede hacer qué" residirá en `app/policies/`.
*   **RBAC (Role-Based Access Control) Dinámico:** Rechazamos los `enums` en el modelo `User` en favor de tablas reales. Esto habilita la creación futura de interfaces para que un administrador gestione permisos sin requerir intervención de desarrollo o un nuevo despliegue[cite: 1].
*   **Bypass explícito para Super Admin:** Para optimizar rendimiento y simplificar el desarrollo base, el rol `super_admin` tendrá un bypass en la validación de memoria, garantizando acceso total sin consultar la tabla de unión.
*   **Memoization de Permisos:** Para evitar el problema de N+1 queries al renderizar vistas complejas (ej. listas con botones de editar/borrar por fila), los permisos del usuario se cargarán en memoria durante la petición.
*   **Fail Secure:** Se inyecta `verify_authorized` a nivel de `ApplicationController`[cite: 3]. Si un desarrollador olvida proteger un endpoint, Rails lanzará un error en desarrollo/test en lugar de dejar la ruta expuesta silenciosamente.

#### Comandos
Agrega la gema al proyecto y genera la estructura base:

```bash
bundle add pundit --version "~> 2.5"
bin/rails generate pundit:install

# Generación del esquema de datos
bin/rails generate model Role name:string:uniq slug:string:uniq
bin/rails generate model Permission resource:string action:string
bin/rails generate model RolePermission role:references permission:references
bin/rails generate migration AddRoleToUsers role:references
```
