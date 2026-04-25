# Лабораторная работа №2. Kubernetes
## Часть 1

1) Установим нужные пакеты (`minikube` и `kubectl`):
  ```
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
  echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
  kubectl: OK
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  ```
  Проверим доступ к кластеру:
  ```
  kubectl get pods -A
  NAMESPACE     NAME                               READY   STATUS    RESTARTS   AGE
  kube-system   coredns-7d764666f9-695k2           1/1     Running   0          33m
  kube-system   etcd-minikube                      1/1     Running   0          34m
  kube-system   kube-apiserver-minikube            1/1     Running   0          34m
  kube-system   kube-controller-manager-minikube   1/1     Running   0          34m
  kube-system   kube-proxy-dltn5                   1/1     Running   0          34m
  kube-system   kube-scheduler-minikube            1/1     Running   0          34m
  kube-system   storage-provisioner                1/1     Running   0          34m
  ```

2) Запустим кластер (minikube поднимает локальный кластер Kubernetes автоматически внутри `Docker`. Используется docker driver, поэтому ноды кластера — это контейнеры)
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

  **Pod** — минимальная единица запуска (контейнеры)
  
  **Deployment** — управляет репликами Pod'ов

  **Service** — даёт стабильный доступ к Pod’ам
  
  **ConfigMap** — хранит конфигурацию

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
   Почему не использовала команду `minikube service local-app-service`? Потому что при тестировании NodePort сервиса доступ осуществлялся через IP minikube (192.168.49.2). При этом сервис корректно отдавал HTTP-ответ (curl подтверждает наличие HTML). Однако отображение в браузере оказалось нестабильным из-за особенностей работы Docker driver minikube и сетевого моста. Для стабильной проверки использовался механизм port-forward, который обеспечивает прямой доступ к сервису через localhost.
   Видим базовую страничку `nginx`, который и был использован в качестве образа, значит, успех! `ConfigMap` передаёт данные в контейнер, но `nginx` не использует переменные окружения для генерации `HTML`, поэтому сообщение не отображается, надо создавать кастомный `.html` файл для таких целей :)
   <img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/92e618ac-835d-4be7-aae4-fd6127662fe9" />

   Для проверки связи между `ConfigMap` и `Pod` выполним команду `kubectl exec`, которая выводит переменные окружения внутри контейнера:
   ```
   kubectl exec -it $(kubectl get pods -l app=web -o name) -- env | grep MESSAGE
   MESSAGE=ITMO Kubernetes server's there for you :)
   ```
   Эта команда позволяет выполнить запрос напрямую внутри запущенного контейнера (пода). Мы выводим переменные окружения (env) и видим, что наше сообщение успешно передано в систему. Это доказывает связь между ресурсами `ConfigMap` и `Deployment`.
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
   
3) К сожалению, созданный ранее `kuber_cfg.yaml` не вписывается в стандарты базовой комплектации, поэтому очищаем папку с шаблонами и строим свою империю
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
     replicas: {{ .Values.replicaCount }}
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
   
4) Изменяем `values.yaml`
	```
	image:
	  repository: nginx
	  tag: "" -> alpine 
	
	service:
	  type: ClusterIP -> NodePort
	  port: 80
	
	message: "ITMO Kubernetes server's there for you :)" (доавила в конец)
	```
5) Деплоим
	```
	helm install my-release .
	NAME: my-release
	LAST DEPLOYED: Sun Apr 12 20:14:16 2026
	NAMESPACE: default
	STATUS: deployed
	REVISION: 1
	TEST SUITE: None
	```
	
	Проверяем работоспособность
	```
	kubectl get pods
	kubectl get svc
	kubectl get configmaps
	NAME                         READY   STATUS    RESTARTS      AGE
	local-app-65d7dfdb6d-kp42w   1/1     Running   1 (44h ago)   44h
	my-release-8ff5b9ff9-q77dx   1/1     Running   0             3m1s
	NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
	kubernetes           ClusterIP   10.96.0.1        <none>        443/TCP        46h
	local-app-service    NodePort    10.103.13.145    <none>        80:30930/TCP   44h
	my-release-service   NodePort    10.108.169.247   <none>        80:31844/TCP   3m1s
	NAME                DATA   AGE
	app-config          1      44h
	kube-root-ca.crt    1      46h
	my-release-config   1      3m1s
	
	curl -I http://192.168.49.2:31844
	HTTP/1.1 200 OK
	Server: nginx/1.29.8
	Date: Sun, 12 Apr 2026 17:50:00 GMT
	Content-Type: text/html
	Content-Length: 896
	Last-Modified: Tue, 07 Apr 2026 12:09:53 GMT
	Connection: keep-alive
	ETag: "69d4f411-380"
	Accept-Ranges: bytes

 	curl -v http://192.168.49.2:31844
	*   Trying 192.168.49.2:31844...
	* Connected to 192.168.49.2 (192.168.49.2) port 31844
	> GET / HTTP/1.1
	> Host: 192.168.49.2:31844
	> User-Agent: curl/8.5.0
	> Accept: */*
	> 
	< HTTP/1.1 200 OK
	< Server: nginx/1.29.8
	< Date: Sun, 12 Apr 2026 17:45:37 GMT
	< Content-Type: text/html
	< Content-Length: 896
	< Last-Modified: Tue, 07 Apr 2026 12:09:53 GMT
	< Connection: keep-alive
	< ETag: "69d4f411-380"
	< Accept-Ranges: bytes
	< 
	<!DOCTYPE html>
	<html>
	<head>
	<title>Welcome to nginx!</title>
	<style>
	html { color-scheme: light dark; }
	body { width: 35em; margin: 0 auto;
	font-family: Tahoma, Verdana, Arial, sans-serif; }
	</style>
	</head>
	<body>
	<h1>Welcome to nginx!</h1>
	<p>If you see this page, nginx is successfully installed and working.
	Further configuration is required for the web server, reverse proxy, 
	API gateway, load balancer, content cache, or other features.</p>
	
	<p>For online documentation and support please refer to
	<a href="https://nginx.org/">nginx.org</a>.<br/>
	To engage with the community please visit
	<a href="https://community.nginx.org/">community.nginx.org</a>.<br/>
	For enterprise grade support, professional services, additional 
	security features and capabilities please refer to
	<a href="https://f5.com/nginx">f5.com/nginx</a>.</p>
	
	<p><em>Thank you for using nginx.</em></p>
	</body>
	</html>
	* Connection #0 to host 192.168.49.2 left intact
    ```
    <img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/0fd4f767-6afb-4681-a24c-ea8fd6eb9683" />
    Все на месте, можно идти вносить изменения!

6) Внесем изменения такие, чтобы в браузере отображалась не приветственная страница `nginx`, а моя фраза `ITMO Kubernetes server's there for you :)`.
	Для этого изменим `ConfigMap` и `Deployment`, добавив тома
	
	В `configmap.yaml` добавим `.html` файл с описанием сайта:
	```
 	apiVersion: v1
	kind: ConfigMap
	metadata:
	  name: {{ .Release.Name }}-html
	data:
	  index.html: |
	    <html>
	      <head><title>ITMO</title></head>
	      <body>
	        <h1>ITMO Kubernetes server's there for you :)</h1>
	      </body>
	    </html>
 	```
 
	В `deployment.yaml` добавим том и примонтируем `index.html` в `nginx`:
	```
 	apiVersion: apps/v1
	kind: Deployment
	metadata:
	  name: {{ .Release.Name }}
	spec:
	  replicas: {{ .Values.replicaCount }}
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
	        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
	
	        volumeMounts:   
	        - name: html
	          mountPath: /usr/share/nginx/html
	
	      volumes:
	      - name: html
	        configMap:
	          name: {{ .Release.Name }}-html
	```
	Использование блока `env` подходит для приложений, которые умеют считывать настройки из переменных окружения. Однако стандартный образ `nginx` работает иначе: он просто отдает статические файлы из определенной папки. Поэтому, чтобы изменить приветственную страницу, мы используем `Volume Mount` (монтирование тома). Мы «подкладываем» наш index.html из ConfigMap прямо в рабочую директорию `nginx` (/usr/share/nginx/html), подменяя стандартный файл своим.

8) Применяем изменения
	```
 	helm upgrade my-release .
	Release "my-release" has been upgraded. Happy Helming!
	NAME: my-release
	LAST DEPLOYED: Sun Apr 12 21:08:34 2026
	NAMESPACE: default
	STATUS: deployed
	REVISION: 2
	TEST SUITE: None
	```
 
 	Проверка работоспособности:
	```
	kubectl get pods
	kubectl get svc
	kubectl get configmaps
	NAME                         READY   STATUS    RESTARTS      AGE
	local-app-65d7dfdb6d-kp42w   1/1     Running   1 (45h ago)   45h
	my-release-b44b797db-m2sgc   1/1     Running   0             77s
	NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
	kubernetes           ClusterIP   10.96.0.1        <none>        443/TCP        47h
	local-app-service    NodePort    10.103.13.145    <none>        80:30930/TCP   45h
	my-release-service   NodePort    10.108.169.247   <none>        80:31844/TCP   55m
	NAME               DATA   AGE
	app-config         1      45h
	kube-root-ca.crt   1      47h
	my-release-html    1      77s
	```

	Но этого оказалось недостаточно!! Из-за одинаковых лэйблов `app: web` в предыдущем класере из первой части и этом `kubectl port-forward svc/my-release-service 8080:80` предательски вел нас на предыдущий под `local-app-service` вместо `my-release-service`. В Kubernetes `Service` находит нужные поды по «селекторам» (`labels`). Так как в первой и второй частях я использовала одинаковый лэйбл `app: web`, сервис запутался и отправлял трафик на старый под из первой части. Чтобы исправить это, я принудительно «заскалила» старый деплой в ноль (`--replicas=0`), оставив в кластере только актуальный под от Helm. В будущем стоит использовать уникальные имена или добавлять префикс `{{ .Release.Name }}` к лэйблам. Поэтому все зрарботало только после следующих манипуляций:
	```
 	kubectl scale deployment local-app --replicas=0
	deployment.apps/local-app scaled
	kubectl get pods
	NAME                         READY   STATUS    RESTARTS   AGE
	my-release-b44b797db-m2sgc   1/1     Running   0          66m
	```
	<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/a1ea649e-ea52-47b6-9075-56d7d39a055e" />
	Ура, теперь мы видим сообщение!

	После `minicube dashboard` мы увидим следующие результаты:
	<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/879acffa-74b3-4eb1-8ae2-450b49bb374b" />

	Deployments: 2 — В кластере живут две инструкции по развертыванию: старая `local-app` (из 1-й части) и новая `my-release` (от Helm).
    Pods: 1 — Несмотря на обилие действий и записей, реально работает сейчас только один под (относящийся к Helm-релизу).
    Replica Sets: 4 — В памяти кластера хранятся 4 набора реплик.

	Разберемся с Replica Sets:
    `local-app-...` (2 штуки): Это хвосты от первой части лабы. Один из них (6798c64dc4) упал с ошибкой CreateContainerConfigError из-за моей невнимательности при выполнении лабы и я делала `kubectl apply` второй раз (но это не точно, я искренне забыла, было ли такое...), а второй (65d7dfdb6d) заработал с новым рабочим конфигом. Сейчас они в статусе `0/0`, то есть места в кластере не занимают, но «память» о них осталась.
    `my-release-8ff5b9ff9` (0/0): первый деплой через Helm.
    `my-release-b44b797db` (1/1): текущий активный релиз.
    В списке ресурсов видны как старые манифесты (`local-app`), так и новый Helm-релиз (`my-release`). Большое количество ReplicaSet объясняется сохранением истории версий: при каждом `helm upgrade` и `kubectl apply` старая версия сохраняется в состоянии 0 реплик для возможности быстрого отката (`rollback`). Статус `1/1` у релиза `my-release` подтверждает, что запрошенная конфигурация полностью развернута и под готов к приему трафика. Статус `0/0` у local-app показывает, что ресурс сохранен в кластере, но не потребляет вычислительные мощности (количество реплик принудительно снижено до нуля).

## Три причины использовать Helm, а не манифесты Kubernetes

- Шаблонизация (Reusability): Мы написали манифест один раз, а текст сообщения и количество реплик вынесли в values.yaml. Это позволяет разворачивать разные версии приложения, не правя код манифестов. Соблюдаем принцип Don't Repeat Yourself ;)
- Управление релизами (Versioning): Helm хранит историю (Revision 1, 2...). Если бы мой новый `index.html` сломал верстку, я бы могла вернуться к первой версии одной командой `helm rollback`.
- Единый цикл управления: Мы создаем, обновляем и удаляем сразу пачку ресурсов (`Deployment`, `Service`, `ConfigMap`) как единое целое («релиз»), а не по отдельности.
