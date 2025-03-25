from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from fake_useragent import UserAgent
import zipfile, random, time, os, tempfile

CHROME_PATH = "/usr/bin/google-chrome"
CHROMEDRIVER_PATH = "/usr/local/bin/chromedriver"

USERNAME_BASE = "Yz3XQbz7vR2z3qmo"
PASSWORD = "rUwiPZvJ8YF5tR0b"
PROXY_HOST = "geo.iproyal.com"
PROXY_PORT = 12321

manifest_json = """
{
    "version": "1.0.0",
    "manifest_version": 2,
    "name": "IPRoyal Proxy",
    "permissions": [
        "proxy", "tabs", "unlimitedStorage", "storage",
        "<all_urls>", "webRequest", "webRequestBlocking"
    ],
    "background": { "scripts": ["background.js"] },
    "minimum_chrome_version":"22.0.0"
}
"""

background_js_template = """
var config = {
    mode: "fixed_servers",
    rules: {
        singleProxy: {
            scheme: "http",
            host: "%s",
            port: parseInt(%s)
        },
        bypassList: ["localhost"]
    }
};
chrome.proxy.settings.set({value: config, scope: "regular"}, function() {});
function callbackFn(details) {
    return {
        authCredentials: { username: "%s", password: "%s" }
    };
}
chrome.webRequest.onAuthRequired.addListener(callbackFn, {urls: ["<all_urls>"]}, ['blocking']);
"""

service = Service(executable_path=CHROMEDRIVER_PATH)

print("[INFO] Lancement boucle navigation...")

iteration = 0
while True:
    iteration += 1
    options = Options()
    options.binary_location = CHROME_PATH
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-blink-features=AutomationControlled")
    options.add_argument("--disable-web-security")
    options.add_argument("--disable-webrtc")
    options.add_argument("--start-maximized")
    options.add_argument("--remote-debugging-port=0")

    user_data_dir = tempfile.mkdtemp()
    options.add_argument(f"--user-data-dir={user_data_dir}")

    ua = UserAgent()
    random_ua = ua.random
    options.add_argument(f"--user-agent={random_ua}")

    session_id = f"agent{random.randint(1000, 9999)}"
    proxy_username = f"{USERNAME_BASE}-country-ch-{session_id}"
    proxy_url = f"http://{PROXY_HOST}:{PROXY_PORT}"

    background_js = background_js_template % (PROXY_HOST, PROXY_PORT, proxy_username, PASSWORD)
    pluginfile = f"proxy_auth_extension_{session_id}.zip"
    with zipfile.ZipFile(pluginfile, 'w') as zp:
        zp.writestr("manifest.json", manifest_json)
        zp.writestr("background.js", background_js)
    options.add_extension(pluginfile)
    options.add_argument(f"--proxy-server={proxy_url}")

    print(f"[INFO] Itération {iteration} - Proxy : {proxy_username}@{PROXY_HOST}:{PROXY_PORT}")
    print(f"[INFO] Itération {iteration} - User-Agent : {random_ua}")

    try:
        driver = webdriver.Chrome(service=service, options=options)
        driver.get("https://abrahamjuliot.github.io/creepjs/")
        time.sleep(8)
        screenshot_name = f"fingerprint_{session_id}.png"
        driver.save_screenshot(screenshot_name)
        print(f"[📸] Screenshot enregistré : {screenshot_name}")
    except Exception as e:
        print(f"[❌ ERREUR] : {e}")
    finally:
        try:
            driver.quit()
        except:
            pass
        try:
            os.remove(pluginfile)
        except:
            pass
        print("[⏳] Pause 2 minutes...\n")
        time.sleep(120)
