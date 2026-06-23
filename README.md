# Parte 3: Levántate y ataca el laboratorio «Black Hat Bash»

Esta sección documenta el despliegue de un laboratorio de ciberseguridad basado en contenedores y la posterior ejecución de una técnica de penetración (Directory Enumeration). Al ser nuestra primera experiencia administrando entornos Unix complejos, utilizamos herramientas de orquestación para simular una infraestructura empresarial realista.

## 3.A — Despliegue y Verificación del Laboratorio

Para montar el entorno de pruebas, clonamos el repositorio oficial de *Black Hat Bash* y utilizamos Docker Compose mediante scripts automatizados (`make`).

**![sudo make deploy](<sudo-make-deploy.png>)**
**![tail -f](<tail-f.png>)**


* **Comandos de despliegue:** * `sudo make deploy` (para orquestar la creación de la red y los contenedores).
  * `tail -f /var/log/lab-install.log` (para monitorear el proceso en tiempo real en Unix).

**![sudo make test y sudo docker ps --format "{{.Names}}](<make-test-and-docker-ps.png>)**

* **Justificación de verificación:** El comando `make test` ejecuta un script de validación de salud de los servicios. Posteriormente, listamos los contenedores activos. Observamos que la infraestructura se divide lógicamente en servicios públicos (`p-*`) y corporativos o internos (`c-*`).

**![Ejecución ip addr | grep "br_](<ip-addr-|-grep-"br_-.png>)**


* **Validación de Redes:** Utilizamos el filtrado `grep` en Linux para aislar nuestras interfaces bridge creadas por Docker. Confirmamos la creación de dos redes aisladas:
  * **Red Pública (`br_public`):** Subred `172.16.10.0/24`. Actúa como nuestra DMZ.
  * **Red Corporativa (`br_corporate`):** Subred `10.1.0.0/24`. Actúa como la red interna segura.

**![Bash con privilegios](<bash-root.png>)**

* **Acceso a la máquina:** Demostramos que tenemos privilegios de administración local sobre el entorno ingresando una sesión interactiva (`bash`) dentro del contenedor web público.

### Arquitectura del Laboratorio

A continuación, se detalla el diagrama lógico y la asignación de IPs de nuestra infraestructura emulada:

| Hostname | Rol del Servidor | IP Pública (`172.16.10.x`) | IP Corporativa (`10.1.0.x`) |
| :--- | :--- | :--- | :--- |
| **`p-web-01`** | Servidor Web 1 (Objetivo) | `172.16.10.10` | N/A |
| **`p-web-02`** | Servidor Web 2 | `172.16.10.11` | N/A |
| **`p-ftp-01`** | Servidor FTP | `172.16.10.12` | N/A |
| **`p-jumpbox-01`**| Servidor de Salto (Pivoting)| `172.16.10.20` | `10.1.0.20` |
| **`c-db-01`** | Base de Datos Principal | N/A | `10.1.0.10` |
| **`c-db-02`** | Base de Datos Réplica | N/A | `10.1.0.11` |
| **`c-redis-01`** | Servidor de Caché (Redis) | N/A | `10.1.0.12` |
| **`c-backup-01`** | Servidor de Respaldos | N/A | `10.1.0.30` |

---

## 3.B — Técnica de Hacking en el Laboratorio (Nivel Intermedio)

Para la fase de explotación, seleccionamos la técnica de **Enumeración de rutas y directorios** utilizando la herramienta `dirsearch`. 

*Nota de pivoteo:* Durante la fase de reconocimiento inicial notamos que el objetivo original (`p-web-01`) ejecutaba un servicio Flask en un puerto no estándar. Aplicando el pensamiento lateral típico de una auditoría real, decidimos pivotar nuestro ataque hacia el servidor **`p-web-02` (IP: 172.16.10.12)**, el cual exponía un servicio HTTP tradicional en el puerto 80.

**![Pruebacurl](<PruebaCurl.png>)**
**![instalación dirsearch](<instalacióndirsearch.png>)**
**![dirsearch1](<dirsearch1.png>)**
**![dirsearch2](<dirsearch2.png>)**


### 1. ¿Qué hace la técnica y por qué funciona?
La enumeración de directorios es un ataque de fuerza bruta a nivel de la capa de aplicación. Utilizando un diccionario de palabras clave predefinido, `dirsearch` lanza miles de peticiones HTTP automatizadas (URL Guessing) contra el objetivo. 

Esta técnica funciona porque explota el principio de "Seguridad por Oscuridad". Muchos administradores asumen erróneamente que si una ruta sensible (como un panel de inicio de sesión o un archivo de configuración) no tiene un enlace público en la página web principal, los atacantes no podrán encontrarla. La herramienta ignora la interfaz visual y consulta directamente al servidor, obligándolo a revelar la existencia del recurso.

### 2. Evidencia y Ejecución
* **Comando ejecutado:** `dirsearch -u http://172.16.10.12/`
* **Resultado:** La herramienta procesó más de 11,460 rutas, obteniendo múltiples respuestas del servidor objetivo.

### 3. Interpretación Técnica de los Resultados (El Hallazgo)
Al analizar la salida de los códigos de estado HTTP, obtuvimos información crítica sobre la infraestructura del objetivo:

1. **Respuestas 403 (Forbidden):** Archivos como `.htaccess` o `/wp-content/cache/` existen, pero el servidor está configurado correctamente para denegar su lectura pública.
2. **Respuestas 200 (OK) y Exposición de CMS:** El mayor descubrimiento fue localizar las rutas `/wp-admin`, `/wp-includes`, `/wp-content` y `/wp-login.php`. 
   * **Interpretación:** El prefijo `wp-` nos confirma con un 100% de certeza que **el servidor web está ejecutando WordPress** como su Sistema de Gestión de Contenidos (CMS). 
3. **Punto de Entrada Localizado:** El hallazgo del código 200 en `/wp-login.php` significa que hemos encontrado el panel de administración principal. 

### 4. Conclusión del Ataque
Como grupo conlcuimos que este resultado es un éxito rotundo. Pasamos de interactuar con una simple página web pública a mapear su arquitectura de backend. Al descubrir que es un sitio WordPress y ubicar su panel de login, la siguiente fase natural de este *pentest* sería utilizar herramientas de auditoría específicas (como `wpscan`) o ejecutar un ataque de fuerza bruta sobre las credenciales para intentar tomar el control total del servidor y, desde ahí, pivotar hacia la red corporativa interna (`10.1.0.x`).