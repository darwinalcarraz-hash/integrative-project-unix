# Part 3: Stand Up and Attack the Black Hat Bash Lab

This section documents the deployment of a container-based cybersecurity lab and the subsequent execution of a penetration testing technique (Directory Enumeration). As our first experience managing complex Unix environments, we used orchestration tools to simulate a realistic enterprise infrastructure.

## 3.A — Lab Deployment and Verification

To set up the test environment, we cloned the official *Black Hat Bash* repository and used Docker Compose through automated scripts (`make`).

**![sudo make deploy](<sudo-make-deploy.png>)**
**![tail -f](<tail-f.png>)**


* **Deployment Commands:**
  * `sudo make deploy` (to orchestrate the creation of networks and containers).
  * `tail -f /var/log/lab-install.log` (to monitor the process in real-time on Unix).

**![sudo make test and sudo docker ps --format "{{.Names}}](<make-test-and-docker-ps.png>)**

* **Verification Rationale:** The `make test` command runs a service health validation script. Subsequently, we list the active containers. We observed that the infrastructure is logically divided into public services (`p-*`) and corporate or internal services (`c-*`).

**![Executing ip addr | grep "br_](<ip-addr-|-grep-"br_-.png>)**


* **Network Validation:** We used `grep` filtering in Linux to isolate our Docker-created bridge interfaces. We confirmed the creation of two isolated networks:
  * **Public Network (`br_public`):** Subnet `172.16.10.0/24`. Acts as our DMZ.
  * **Corporate Network (`br_corporate`):** Subnet `10.1.0.0/24`. Acts as the secure internal network.

**![Bash with Privileges](<bash-root.png>)**

* **Machine Access:** We demonstrated that we have local administrative privileges over the environment by entering an interactive session (`bash`) within the public web container.

### Lab Architecture

Below is the logical diagram and IP assignment of our emulated infrastructure:

![ip-consulta](<ipconsultas.png>)

| Hostname | Server Role | Public IP (`172.16.10.x`) | Corporate IP (`10.1.0.x`) |
| :--- | :--- | :--- | :--- |
| **`p-web-01`** | Web Server 1 (Target) | `172.16.10.10` | N/A |
| **`p-web-02`** | Web Server 2 | `172.16.10.12` | N/A |
| **`p-ftp-01`** | FTP Server | `172.16.10.11` | N/A |
| **`p-jumpbox-01`**| Jump/Pivot Server| `172.16.10.13` | `10.1.0.12` |
| **`c-db-01`** | Primary Database | N/A | `10.1.0.15` |
| **`c-db-02`** | Database Replica | N/A | `10.1.0.16` |
| **`c-redis-01`** | Cache Server (Redis) | N/A | `10.1.0.14` |
| **`c-backup-01`** | Backup Server | N/A | `10.1.0.13` |

---

## 3.B — Hacking Technique in the Lab (Intermediate Level)

For the exploitation phase, we selected the **Directory and Path Enumeration** technique using the `dirsearch` tool. 

*Pivot Note:* During the initial reconnaissance phase, we noticed that the original target (`p-web-01`) was running a Flask service on a non-standard port. Applying lateral thinking typical of real-world audits, we decided to pivot our attack toward the **`p-web-02` server (IP: 172.16.10.12)**, which exposed a traditional HTTP service on port 80.

**![Curl Test](<PruebaCurl.png>)**
**![dirsearch Installation](<instalacióndirsearch.png>)**
**![dirsearch1](<dirsearch1.png>)**
**![dirsearch2](<dirsearch2.png>)**


### 1. What Does the Technique Do and Why Does It Work?
Directory enumeration is a brute-force attack at the application layer. Using a predefined keyword dictionary, `dirsearch` launches thousands of automated HTTP requests (URL Guessing) against the target. 

This technique works because it exploits the principle of "Security Through Obscurity." Many administrators mistakenly assume that if a sensitive path (such as a login panel or configuration file) doesn't have a public link on the main webpage, attackers won't be able to find it. The tool ignores the visual interface and queries the server directly, forcing it to reveal the existence of the resource.

### 2. Evidence and Execution
* **Command Executed:** `dirsearch -u http://172.16.10.12/`
* **Result:** The tool processed over 11,460 paths, obtaining multiple responses from the target server.

### 3. Technical Interpretation of Results (The Discovery)
By analyzing the HTTP status code output, we obtained critical information about the target infrastructure:

1. **403 (Forbidden) Responses:** Files such as `.htaccess` or `/wp-content/cache/` exist, but the server is correctly configured to deny public read access.
2. **200 (OK) Responses and CMS Exposure:** The major discovery was locating the paths `/wp-admin`, `/wp-includes`, `/wp-content`, and `/wp-login.php`. 
   * **Interpretation:** The `wp-` prefix confirms with 100% certainty that **the web server is running WordPress** as its Content Management System (CMS). 
3. **Entry Point Located:** The discovery of status code 200 at `/wp-login.php` means we have found the main administration panel. 

### 4. Attack Conclusion
As a team, we concluded that this result is a resounding success. We went from interacting with a simple public webpage to mapping its backend architecture. By discovering that it is a WordPress site and locating its login panel, the natural next phase of this *pentest* would be to use specific audit tools (such as `wpscan`) or execute a brute-force attack on the credentials to attempt to take full control of the server and, from there, pivot toward the internal corporate network (`10.1.0.x`).

---
*Developed by: Keyla Imba (DDK Group)*