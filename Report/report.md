# TIC3001 Task 1A
- Name: Ke Yule
- Student Number: A0211495H E0493826
- Github: https://github.com/keyule/3001-Task1B

*View the markdown version for better formatting at:*   
*placeholder* 

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

![Task 1.5 Verify Pods](https://github.com/keyule/3001-Task1B/blob/main/Report/Screenshots/1.4Verify.png?raw=true)

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

![Task 1.5 Verify Service 1](https://github.com/keyule/3001-Task1B/blob/main/Report/Screenshots/1.4Verify.png?raw=true)

- Localhost should return an nginx 404 as well

![Task 1.5 Verify Service 2](https://github.com/keyule/3001-Task1B/blob/main/Report/Screenshots/1.4Verify.png?raw=true)