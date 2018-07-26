export instance_type=n1-standard-8
export instance_name=fusion-4-1-0
export centos7ver=v20180716

# Create firewall rule for Fusion Console (port 8764) (tag instances w/ 'fusion-server')
gcloud compute --project="$GOOGLE_CLOUD_PROJECT" firewall-rules create allow-fusion --network=default --allow=tcp:8764 --source-ranges=0.0.0.0/0 --target-tags=fusion-server

gcloud compute --project "$GOOGLE_CLOUD_PROJECT" instances create "$instance_name" \
  --zone "us-central1-c" --machine-type "$instance_type" --subnet "default" \
  --metadata "startup-script=curl https://raw.githubusercontent.com/lucidworks/fusion-examples/master/misc/scripts/RHEL_7_Fusion_Setup.sh >setup.sh && chmod +x setup.sh && ./setup.sh" \
  --no-restart-on-failure --maintenance-policy "TERMINATE" --preemptible \
  --service-account "731036704764-compute@developer.gserviceaccount.com" \
  --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
  --tags "http-server","https-server","fusion-server" \
  --image "centos-7-$centos7ver" --image-project "centos-cloud" \
  --boot-disk-size "100" --boot-disk-type "pd-ssd" --boot-disk-device-name "$instance_name"
