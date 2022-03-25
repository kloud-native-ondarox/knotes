# Deploying Airgap and Karbon Darksite

## Build web server

- Linux - https://portal.nutanix.com/page/documents/details?targetId=Life-Cycle-Manager-Dark-Site-Guide-v2_4:2-lcm-darksite-web-server-linux-t.html
- Windows - https://portal.nutanix.com/page/documents/details?targetId=Life-Cycle-Manager-Dark-Site-Guide-v2_4:2-lcm-darksite-web-server-windows-t.html

## Fetch Karbon Dark Site Bundle (if upgrading Karbon via LCM Darksite)

- https://portal.nutanix.com/page/documents/details?targetId=Life-Cycle-Manager-Dark-Site-Guide-v2_4:2-lcm-darksite-karbon-update-t.html

## Deploy Airgap

- https://portal.nutanix.com/page/documents/details?targetId=Karbon-v2_2:kar-karbon-airgap-c.html

### Create Directory on webserver

`sudo mkdir -p -m 755 /var/www/html/release/ntnx-2.2.0/`

`sudo curl https://download.nutanix.com/karbon/airgap/2.2.0/airgap-manifest.json -o airgap-manifest.json`

# Download Karbon 2.2.0 Upgrade

```Bash
sudo mkdir -p -m 755 /var/www/html/release/ntnx-2.2.0
cd /var/www/html/release/ntnx-2.2.0
sudo curl -o airgap-manifest.json https://download.nutanix.com/karbon/airgap/2.2.0/airgap-manifest.json
sudo curl -O -J -L https://download.nutanix.com/karbon/airgap/2.2.0/airgap-ntnx-2.2.0.tar.gz?Expires=1614293214540&Key-Pair-Id=APKAJTTNCWPEI42QKMSA&Signature=g6i1Yb~aUsOMyJ77g2AcMOqDXaa7DhkPN8y~8QKczNxUeqTBL0GoCjw1mtyw4ItbE4ICiediuvxH25PDtKzhXPd6crn5rdg8ZiI1aYz0fhriGC8sbokg-xfxE6cOYMEjQjAiv6vulT3Q0nkEnUOkn2tnNQYFQ0E7UO8XXkuON98ze6rVD8P4U2UyVUw~kghImF-0INe1JIJV2NuHUIdUFvDPC906lgdeCIYsuVB3rzCptgQ5E-C5VwNJUTUbgV6Xt304d1amrLjbDhsJgT14IMaB9BTPEBQAujSjhd~7YQSXGci5FXUd-zz1f33czuOEkw~4aFO03NanxIXBzfDvzg__ && sudo tar xvf airgap-ntnx-2.2.0.tar.gz
```

# Download Karbon 2.2.1 Upgrade

```Bash
sudo mkdir -p -m 755 /var/www/html/release/ntnx-2.2.1
cd /var/www/html/release/ntnx-2.2.1
sudo curl -o airgap-manifest.json https://download.nutanix.com/karbon/airgap/2.2.1/airgap-manifest.json
sudo curl -O -J -L https://download.nutanix.com/karbon/2.2.1/airgap-ntnx-2.2.1.tar.gz?Expires=1614293352140&Key-Pair-Id=APKAJTTNCWPEI42QKMSA&Signature=BPznQ2UUM51AkrPE38ckeh8wVDJbY7YeSU5okQBTSw6d~LC2vRNkLKWx5wAZucik0~VNnbNCzlAuF5RyFsOrdL-zlUK7kd-zCIor1siNoTjad5cqIn~7~yqb7hfIluKifIB3E1JtDEfbjhhP~DpA03QPwgQcnliWkSbwm3wYozL7I2XTDYBolgMTHoewh7OdvsP~8EKC-803RnLwmEyhRIp28w9td1V4v5q~S1C7034HraAkPTRIWM2QIQxGjva05c4enAIGqWBWmQnwO1DBxzWr-KsieaSmkTAUPwS5iEtx~Mxluk~5sKe6PyLCNFGpGdY7I9gZBNgiWA-7O3KSiQ__ && sudo tar xvf airgap-ntnx-2.2.1.tar.gz
```

### Execute commands via Karbonctl

./karbonctl login --pc-ip 10.38.18.150 --pc-username admin --pc-password 'nx2Tech430!'

./karbonctl airgap enable \
--webserver-url http://10.38.18.176/release/ntnx-2.2.0/ \
--vlan-name Primary --static-ip 10.38.18.150 \
--storage-container SelfServiceContainer \
--pe-cluster-name PHX-SPOC018-3 --pe-username admin \
--pe-password 'nx2Tech430!' \
--dry-run
