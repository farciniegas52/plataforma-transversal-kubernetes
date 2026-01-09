# Network Load Balancers (NLB) - Helm Chart

Este Helm Chart crea Network Load Balancers (NLB) en AWS para tráfico TCP/UDP (capa 4).

## 🎯 Objetivo

Crear NLBs para aplicaciones que requieren:
- Tráfico TCP/UDP (no HTTP/HTTPS)
- Máxima performance y baja latencia
- Conexiones de larga duración
- Protocolos personalizados

## 📦 ¿Cuándo usar NLB vs ALB?

| Usa NLB cuando | Usa ALB cuando |
|----------------|----------------|
| Necesitas TCP/UDP | Necesitas HTTP/HTTPS |
| Bases de datos | APIs REST |
| gRPC | Aplicaciones web |
| WebSockets | Enrutamiento por host/path |
| Protocolos custom | Necesitas IngressGroups |

## 📝 Configuración

Todo se controla desde `values.yaml`:

```yaml
loadBalancers:
  - name: public-nlb
    enabled: true
    scheme: internet-facing
    targetType: ip
    crossZoneLoadBalancing: true
    healthcheck:
      protocol: HTTP
      port: 80
      path: /
    ports:
      - name: http
        port: 80
        targetPort: 80
        protocol: TCP
```

## ✏️ Cómo agregar un nuevo NLB

### Ejemplo: NLB para base de datos

```yaml
loadBalancers:
  - name: database-nlb
    enabled: true
    scheme: internal
    replicas: 2
    htmlTitle: "🗄️ Balanceador Database"
    htmlDescription: "Network Load Balancer - Database Access"
    htmlGradient: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)"
    loadBalancerName: pragma-eks-platform-dev-nlb-database
    targetType: ip
    crossZoneLoadBalancing: true
    healthcheck:
      protocol: TCP
      port: 5432
      intervalSeconds: 30
    ports:
      - name: postgres
        port: 5432
        targetPort: 5432
        protocol: TCP
    tags:
      Environment: dev
      Type: database
```

### Ejemplo: NLB multi-puerto

```yaml
loadBalancers:
  - name: multi-port-nlb
    enabled: true
    scheme: internet-facing
    ports:
      - name: http
        port: 80
        targetPort: 8080
        protocol: TCP
      - name: https
        port: 443
        targetPort: 8443
        protocol: TCP
      - name: grpc
        port: 9090
        targetPort: 9090
        protocol: TCP
```

## 🚀 Cómo usar estos NLBs

Los NLBs se crean automáticamente cuando habilitas un balanceador. Para conectar tu aplicación:

### Opción 1: Usar el NLB directamente

```bash
# Obtener la URL del NLB
kubectl get svc public-nlb -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Conectar desde tu aplicación
# Ejemplo: postgres://public-nlb-xxx.elb.us-east-1.amazonaws.com:5432
```

### Opción 2: Crear tu propio Service que use el NLB

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mi-app-nlb
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "external"
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
spec:
  type: LoadBalancer
  loadBalancerClass: service.k8s.aws/nlb
  selector:
    app: mi-app
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
```

## 📊 Estructura del Helm Chart

```
network-load-balancers/
├── Chart.yaml
├── values.yaml                   # ⭐ Configuración principal
├── README.md
└── templates/
    ├── _helpers.tpl
    ├── configmap.yaml            # HTML para apps dummy
    ├── deployment.yaml           # Pods dummy
    └── service-nlb.yaml          # Service LoadBalancer (crea NLB)
```

## 🚀 Validación

```bash
# Ver los Services NLB
kubectl get svc -n default -l app.kubernetes.io/name=*-nlb-dummy

# Ver detalles de un NLB
kubectl describe svc public-nlb -n default

# Ver NLBs en AWS
aws elbv2 describe-load-balancers --region us-east-1 --profile pra_academia_poc

# Obtener URL de un NLB
kubectl get svc public-nlb -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Probar el chart localmente
helm template network-load-balancers . -f values.yaml

# Validar sintaxis
helm lint .
```

## 📝 Configuraciones importantes

### Target Type
- **ip**: Enruta directamente a IPs de pods (recomendado para Fargate)
- **instance**: Enruta a instancias EC2 (recomendado para NodeGroups)

### Health Check Protocols
- **TCP**: Solo verifica conectividad TCP
- **HTTP/HTTPS**: Verifica respuesta HTTP (más robusto)

### Cross-Zone Load Balancing
- **true**: Distribuye tráfico entre todas las AZs (recomendado)
- **false**: Solo dentro de la misma AZ (menor costo pero menos resiliente)

## 💰 Costos

- **Costo base**: ~$16/mes por NLB
- **LCU (Load Balancer Capacity Units)**: ~$0.006 por LCU-hora
- **Procesamiento de datos**: Varía según tráfico

## 🔄 Workflow de cambios

1. Edita `values.yaml`
2. Habilita/deshabilita NLBs con `enabled: true/false`
3. Commit y push al repositorio
4. ArgoCD despliega automáticamente

## 🔗 Desplegar con ArgoCD

Crea una Application en `clusters/eks-cluster/app-network-load-balancers.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: network-load-balancers
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/farciniegas52/plataforma-transversal-kubernetes.git
    targetRevision: main
    path: componentes/network-load-balancers
    helm:
      releaseName: network-load-balancers
      valueFiles:
        - values.yaml
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```
