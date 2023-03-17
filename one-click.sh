
# Place your commands here

base64 -d <<<"H4sIAAAAAAAAA9NThgI9IIBSejARmKienh6cAVfPy4UsCaSh0pg8iCYEV1kZRS9cCsUiOEdPD7de
JBMQblZG0orHzcpwURQfkGgvdv+S7GYUCbAgkpt5uXTJBwCpuiaj4QEAAA==" | gunzip

echo -e "\nBuilding docker Image ... " ;

docker build -t custom-image:mytag ./app/. ; 

echo -e "\nSetting up kind Cluster ... " ; 

kind create cluster --name kind-1 --config k8s/kind/cluster-config.yaml ; 

echo -e "\nLoading image into cluster ... " ; 

kind load docker-image custom-image:mytag --name kind-1; 

echo -e "\nApplying deployment manifest ... " ; 

kubectl apply -f test_deployment.yaml ; 

echo -e "\nApplying nginx-ingress-controller ... " ; 

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml ;


while [[ "$(kubectl -n ingress-nginx get deploy ingress-nginx-controller | tail -n 1 | awk '{print $2}')" != "1/1" ]]; do
  echo "Waiting for deployment to become available... (current status: $(kubectl -n ingress-nginx get deploy ingress-nginx-controller | tail -n 1 | awk '{print $2}'))"
  sleep 5
done

echo "Deployment is ready!"


echo -e "\nLabeling workers as ingress ready ... " ;

kubectl label node kind-1-worker2 ingress-ready=true; 
kubectl label node kind-1-worker3 ingress-ready=true; 

echo -e "\nApplying service ... " ;

kubectl apply -f test_service.yaml ; 

echo -e "\nApplying ingress Object ... " ;

kubectl apply -f test_ingressobject.yaml ; 

echo -e "\nShould be done ... " ;

while ! curl -s -I localhost/app/ | grep "HTTP/1.1 200 OK" >/dev/null; do
  echo "Waiting for the webpage to become available..."
  sleep 5
done
echo "Webpage is up!";
echo -e "Opening localhost on default browser ... " ;

start "http://localhost/app/" ; 