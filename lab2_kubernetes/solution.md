# Лабораторная работа №2. Kubernetes
## Часть 1

1) Установим нужные пакеты (`minikube`, `kubectl` и `Lens`):
  ```
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
  echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
  kubectl: OK
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  kubectl get pods -A
  NAMESPACE     NAME                               READY   STATUS    RESTARTS   AGE
  kube-system   coredns-7d764666f9-695k2           1/1     Running   0          33m
  kube-system   etcd-minikube                      1/1     Running   0          34m
  kube-system   kube-apiserver-minikube            1/1     Running   0          34m
  kube-system   kube-controller-manager-minikube   1/1     Running   0          34m
  kube-system   kube-proxy-dltn5                   1/1     Running   0          34m
  kube-system   kube-scheduler-minikube            1/1     Running   0          34m
  kube-system   storage-provisioner                1/1     Running   0          34m
  sudo snap install kontena-lens --classic
  ```

2) Запустим кластер
  ```
  minikube start
  😄  minikube v1.38.1 on Ubuntu 24.04
  ✨  Using the docker driver based on existing profile
  👍  Starting "minikube" primary control-plane node in "minikube" cluster
  🚜  Pulling base image v0.0.50 ...
  🔄  Restarting existing docker container for "minikube" ...
  🐳  Preparing Kubernetes v1.35.1 on Docker 29.2.1 ...
  🔎  Verifying Kubernetes components...
      ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
      ▪ Using image docker.io/kubernetesui/metrics-scraper:v1.0.8
      ▪ Using image docker.io/kubernetesui/dashboard:v2.7.0
  💡  Some dashboard features require the metrics-server addon. To enable all features please run:

	minikube addons enable metrics-server

  🌟  Enabled addons: default-storageclass, storage-provisioner, dashboard
  🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
  minikube dashboard
  ```
  и увидим, что все работает!
  <img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/e6b5a670-1ece-4f9e-a77c-337d23286f06" />

3) Изучим, какие ресурсы нам вообще достубны в `Kubernetes`
  ```
  kubectl api-resources
  NAME                                SHORTNAMES   APIVERSION                        NAMESPACED   KIND
  bindings                                         v1                                true         Binding
  componentstatuses                   cs           v1                                false        ComponentStatus
  configmaps                          cm           v1                                true         ConfigMap
  endpoints                           ep           v1                                true         Endpoints
  events                              ev           v1                                true         Event
  limitranges                         limits       v1                                true         LimitRange
  namespaces                          ns           v1                                false        Namespace
  nodes                               no           v1                                false        Node
  persistentvolumeclaims              pvc          v1                                true         PersistentVolumeClaim
  persistentvolumes                   pv           v1                                false        PersistentVolume
  pods                                po           v1                                true         Pod
  podtemplates                                     v1                                true         PodTemplate
  replicationcontrollers              rc           v1                                true         ReplicationController
  resourcequotas                      quota        v1                                true         ResourceQuota
  secrets                                          v1                                true         Secret
  serviceaccounts                     sa           v1                                true         ServiceAccount
  services                            svc          v1                                true         Service
  ...
  daemonsets                          ds           apps/v1                           true         DaemonSet
  deployments                         deploy       apps/v1                           true         Deployment
  ...
  ```
  Для первого сервиса пойдем по базовому набору ресурсов: `Deployment`, `Sevice` и `ConfigMap`. Напишем миловидный `yaml` файл:
  ```
  touch kuber_cfg.yaml
  vim kuber_cfg.yaml 
  cat kuber_cfg.yaml 
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: app-config
  data:
    message: "ITMO Kubernetes server's there for you :)"
  ---
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: local-app
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: web
    template:
      metadata:
        labels:
          app: web
      spec:
        containers:
        - name: nginx
          image: nginx:alpine
          env:
          - name: MESSAGE
            valueFrom:
              configMapKeyRef:
                name: app-config
                key: message
  ---
  apiVersion: v1
  kind: Service
  metadata:
    name: local-app-service
  spec:
    type: NodePort
    selector:
      app: web
    ports:
      - port: 80
        targetPort: 80
  ```
  Теперь давайте задеплоим наш сервис в кластер:
  ```
  kubectl apply -f kuber_cfg.yaml
  deployment.apps/local-app created
  service/local-app-service created
  configmap/app-config created
  ```
  Все успешно создалось и работает!
  ```
  kubectl get cm
  NAME               DATA   AGE
  app-config         1      2m20s
  kube-root-ca.crt   1      94m

  kubectl get pods
  NAME                         READY   STATUS    RESTARTS   AGE
  local-app-65d7dfdb6d-kp42w   1/1     Running   0          12s
  ```

  Посмотрим на визуализацию по команде `minicube dashboard`
  <img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/36c6a904-c61f-4e6f-9fa7-dc7ef988571f" />


4) Проверим, как наш сервис поживает на просторах необъятного. Так как `minicube` автоматически в качестве драйвера назначил `docker`, надо проложить путь к сервису:
   ```
   kubectl port-forward service/local-app-service 8080:80
   Forwarding from 127.0.0.1:8080 -> 80
   Forwarding from [::1]:8080 -> 80
   Handling connection for 8080
   ```
   Видим базовую страничку `nginx`, который и был использован в качестве образа, значит, успех! `ConfigMap` передаёт данные в контейнер, но `nginx` не использует переменные окружения для генерации `HTML`, поэтому сообщение не отображается, надо создавать кастомный `.html` файл для таких целей :)
   <img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/92e618ac-835d-4be7-aae4-fd6127662fe9" />

   Для проверки связи между `ConfigMap` и `Pod` выполним команду `kubectl exec`, которая выводит переменные окружения внутри контейнера:
   ```
   kubectl exec -it $(kubectl get pods -l app=web -o name) -- env | grep MESSAGE
   MESSAGE=ITMO Kubernetes server's there for you :)
   ```
   Получается, работосособность доказали :)


## Часть 2
1) Установка `helm`
   ```
   curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
   echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
   sudo apt-get update
   sudo apt-get install helm
   ```
2) Создаем чарт
   ```
   helm create kuber-lab
   Creating kuber-lab
   ```
   
   Заходим в создавшуюся папку, изучаем, что нам дается в базовой комплектации
   ```
   cd kuber-lab/
   ls -al
   total 32
   drwxr-xr-x 4 liza liza 4096 Apr 12 17:43 .
   drwxrwxr-x 3 liza liza 4096 Apr 12 17:43 ..
   drwxr-xr-x 2 liza liza 4096 Apr 12 17:43 charts
   -rw-r--r-- 1 liza liza 1145 Apr 12 17:43 Chart.yaml
   -rw-r--r-- 1 liza liza  349 Apr 12 17:43 .helmignore
   drwxr-xr-x 3 liza liza 4096 Apr 12 17:43 templates
   -rw-r--r-- 1 liza liza 5255 Apr 12 17:43 values.yaml
   ls -al templates/
   total 44
   drwxr-xr-x 3 liza liza 4096 Apr 12 17:43 .
   drwxr-xr-x 4 liza liza 4096 Apr 12 17:43 ..
   -rw-r--r-- 1 liza liza 2390 Apr 12 17:43 deployment.yaml
   -rw-r--r-- 1 liza liza 1802 Apr 12 17:43 _helpers.tpl
   -rw-r--r-- 1 liza liza  997 Apr 12 17:43 hpa.yaml
   -rw-r--r-- 1 liza liza  957 Apr 12 17:43 httproute.yaml
   -rw-r--r-- 1 liza liza 1094 Apr 12 17:43 ingress.yaml
   -rw-r--r-- 1 liza liza 2826 Apr 12 17:43 NOTES.txt
   -rw-r--r-- 1 liza liza  393 Apr 12 17:43 serviceaccount.yaml
   -rw-r--r-- 1 liza liza  367 Apr 12 17:43 service.yaml
   drwxr-xr-x 2 liza liza 4096 Apr 12 17:43 tests
   ```
   
   К сожалению, созданный ранее `kuber_cfg.yaml` не вписывается в стандарты базовой комплектации, поэтому очищаем папку с шаблонами и строим свою империю
   ```
   rm -rf templates/*
   touch templates/configmap.yaml
   touch templates/deployment.yaml
   touch templates/service.yaml
   ```

   Содержание `.yaml` файлов будет такое
   ```
   cat templates/configmap.yaml 
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: {{ .Release.Name }}-config
   data:
     message: "{{ .Values.message }}"
   cat templates/deployment.yaml 
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: {{ .Release.Name }}
   spec:
     replicas: {{ .Values.replicas }}
     selector:
       matchLabels:
         app: web
     template:
       metadata:
         abels:
           app: web
       spec:
         containers:
         - name: nginx
           image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
           env:
           - name: MESSAGE
             valueFrom:
               configMapKeyRef:
                 name: {{ .Release.Name }}-config
                 key: message
   cat templates/service.yaml 
   apiVersion: v1
   kind: Service
   metadata:
     name: {{ .Release.Name }}-service
   spec:
     type: {{ .Values.service.type }}
     selector:
       app: web
     ports:
       - port: {{ .Values.service.port }}
         targetPort: 80
   ```
