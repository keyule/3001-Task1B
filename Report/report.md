# TIC3001 Task 1A
- Name: Ke Yule
- Student Number: A0211495H E0493826
- Github: https://github.com/keyule/3001-Task1B

*View the markdown version for better formatting at:*   
*https://github.com/keyule/3001-Task1B/blob/main/Report/report.md* 

### Task 1.4 - Deploy a local k8s cluster

#### 1.4.1 Create Cluster
- `kind create cluster --name kind-1 --config k8s/kind/cluster-config.yaml`

![Task 1.4 Create](https://github.com/keyule/3001-Task1B/blob/main/Report/Screenshots/1.4Create.png?raw=true)

#### 1.4.2 Verify Cluster 
- `kubectl cluster-info`
- `kubectl get nodes`

![Task 1.4 Verify](https://github.com/keyule/3001-Task1B/blob/main/Report/Screenshots/1.4Verify.png?raw=true)

### Task 1.5 - Deploy 1A Image

#### 1.5.1 Build & Load Image into Cluster
- `docker build -t custom-image:mytag ./app/.`
- `kind load docker-image custom-image:mytag --name kind-1`
- Verify image loaded: `docker exec -it kind-1-worker crictl images`

#### 1.5.2 Create deployment 

- Deployment Script: *test_deployment.yaml*
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  labels:
    app: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend
          image: custom-image:mytag
          ports:
            - name: http
              containerPort: 3000
          resources:
            limits:
              cpu: 40m
              memory: 100Mi
```

- `kubectl apply -f test_deployment.yaml`
- Verify with: `kubectl get pods`
- or `kubectl get deployment/backend --watch` *I prefer to just get pods*

![Task 1.5 Verify Pods](https://github.com/keyule/3001-Task1B/blob/main/Report/Screenshots/1.5VerifyPods.png?raw=true)

#### 1.5.3 Create Service

- Service Script: *test_service.yaml*
```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: backend
  name: backend
spec:
  selector:
    app: backend
  type: ClusterIP
  ports:
    - name: http
      port: 3000
      protocol: TCP
      targetPort: 3000
```
- `kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml`
- wait for it to be ready with ` kubectl -n ingress-nginx get deploy -w`
- `kubectl apply -f test_service.yaml`
- Verify with: `kubectl get svc`

![Task 1.5 Verify Service 1](https://github.com/keyule/3001-Task1B/blob/main/Report/Screenshots/1.5VerifyService1.png?raw=true)

- Localhost should return an nginx 404 as well

![Task 1.5 Verify Service 2](https://github.com/keyule/3001-Task1B/blob/main/Report/Screenshots/1.5VerifyService2.png?raw=true)

### Task 1.6 - Create Ingress Controller 

#### 1.6.1 Create Controller
- label nodes as ingress ready
- `kubectl label node <Node Name> ingress-ready=true`

- Ingress Script: *test_ingressobject.yaml*
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: backend
  labels:
    app: backend
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$1
spec:
  rules:
    - http:
        paths:
          - path: /app/?(.*)
            pathType: Prefix
            backend:
              service:
                name: backend
                port:
                  name: http
```

- kubectl apply -f test_ingressobject.yaml

#### 1.6.2 Verify Ingress

- `kubectl get ingress`

![Task 1.6 Verify Ingress](https://github.com/keyule/3001-Task1B/blob/main/Report/Screenshots/1.6VerifyIngress.png?raw=true)

#### Done!

- Task 1A should be rendered on `http://localhost/app/`

![Local Host](https://github.com/keyule/3001-Task1B/blob/main/Report/Screenshots/final.png?raw=true)

> *Note: Only works with the extra `/` at the end. I have no idea why. Its most probably how I set up my rules in ingress object. If I remove the `/app` and set my rule as just `/?(.*)` it would work if i visit localhost.* 

### Appendix 

#### One-Click.sh File 

```
# this first line just prints a banner 
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
```