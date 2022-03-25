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



### Execute commands via Karbonctl

./karbonctl login --pc-ip <> --pc-username admin --pc-password '<>'

./karbonctl airgap enable \
--webserver-url http://10.38.18.176/release/ntnx-2.2.0/ \
--vlan-name Primary --static-ip 10.38.18.150 \
--storage-container SelfServiceContainer \
--pe-cluster-name <> --pe-username admin \
--pe-password '<>' \
--dry-run
