# Load Balancers - Balanceadores Compartidos (Helm Chart)

Este Helm Chart crea Application Load Balancers (ALB) y Network Load Balancers (NLB) para el cluster.

## 🎯 Objetivo

Crear balanceadores centralizados que pueden ser reutilizados por múltiples aplicaciones, evitando la creación de un balanceador por cada microservicio.

## 📦 Tipos de Balanceadores

### ALB - Application Load Balancer (Capa 7 - HTTP/HTTPS)
- Usa `Ingress` de Kubernetes
- Soporta IngressGroups (compartir ALB entre apps)
- Enrutamiento basado en host/path
- Ideal para aplicaciones web y APIs REST

### NLB - Network Load Balancer (Capa 4 - TCP/UDP)
- Usa `Service` tipo LoadBalancer
- Mejor performance y menor latencia
- Soporta protocolos TCP/UDP
- Ideal para aplicaciones que no son HTTP

## 📝 Configuración

Todo se controla desde `values.yaml`:

```yaml
loadBalancers:
  # ALB Público
  - name: public
    enabled: true
    type: alb              # ← alb o nlb
    scheme: internet-facing
    groupName: public      # Solo para ALB
    alb:                   # Configuración específica de ALB
      targetType: ip
      healthcheck:
        path: /
    
  # NLB Público  
  - name: public-nlb
    enabled: true
    type: nlb              # ← Tipo NLB
    scheme: internet-facing
    nlb:                   # Configuración específica de NLB
      targetType: ip
      crossZoneLoadBalancing: true
      healthcheck:
        protocol: HTTP
        port: 80
```

## ✏️ Cómo agregar un nuevo balanceador

### Agregar un ALB:

```yaml
loadBalancers:
  - name: api
    enabled: true
    type: alb
    scheme: internet-facing
    groupName: api
    groupOrder: 1
    replicas: 2
    htmlTitle: "🚀 Balanceador API"
    htmlDescription: "Application Load Balancer - API Gateway"
    htmlGradient: "linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)"
    loadBalancerName: pragma-eks-platform-dev-alb-api
    alb:
      ingressClassName: alb
      targetType: ip
      healthcheck:
        path: /health
        intervalSeconds: 30
    tags:
      Environment: dev
      Type: api
```

### Agregar un NLB:

```yaml
loadBalancers:
  - name: tcp-service
    enabled: true
    type: nlb
    scheme: internal
    replicas: 2
    htmlTitle: "⚡ Balanceador TCP"
    htmlDescription: "Network Load Balancer - TCP Services"
    htmlGradient: "linear-gradient(135deg, #fa709a 0%, #fee140 100%)"
    loadBalancerName: pragma-eks-platform-dev-nlb-tcp
    nlb:
      targetType: ip
      crossZoneLoadBalancing: true
      healthcheck:
        protocol: TCP
        port: 8080
        intervalSeconds: 30
    tags:
      Environment: dev
      Type: tcp
```

## 🔧 Cómo usar estos balanceadores

### Usar un ALB (con IngressGroup):

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mi-app-ingress
  annotations:
    alb.ingress.kubernetes.io/group.name: public  # ← Usa el ALB público
    alb.ingress.kubernetes.io/group.order: "10"
spec:
  ingressClassName: alb
  rules:
  - host: mi-app.ejemplo.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: mi-app-service
            port:
              number: 80
```

### Usar un NLB:

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
load-balancers/
├── Chart.yaml
├── values.yaml                   # ⭐ Configuración principal
├── README.md
└── templates/
    ├── _helpers.tpl
    ├── configmap.yaml            # HTML para apps dummy
    ├── deployment.yaml           # Pods dummy (ALB y NLB)
    ├── service.yaml              # Service ClusterIP (para ALB)
    ├── ingress.yaml              # Ingress (solo para type=alb)
    └── service-nlb.yaml          # Service LoadBalancer (solo para type=nlb)
```

## 🚀 Validación

```bash
# Ver todos los recursos
kubectl get ingress,svc -n default

# Ver ALBs
kubectl get ingress -n default

# Ver NLBs
kubectl get svc -n default -l app.kubernetes.io/name=*-lb-dummy

# Ver balanceadores en AWS
aws elbv2 describe-load-balancers --region us-east-1 --profile pra_academia_poc

# Obtener URL de un ALB
kubectl get ingress public-lb-ingress -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Obtener URL de un NLB
kubectl get svc public-nlb-lb-nlb -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## 📝 Diferencias clave ALB vs NLB

| Característica | ALB | NLB |
|----------------|-----|-----|
| **Capa OSI** | 7 (HTTP/HTTPS) | 4 (TCP/UDP) |
| **Recurso K8s** | Ingress | Service LoadBalancer |
| **IngressGroup** | ✅ Sí (compartir ALB) | ❌ No |
| **Enrutamiento** | Host/Path | Puerto/Protocolo |
| **Performance** | Buena | Excelente |
| **Latencia** | ~ms | ~µs |
| **Costo** | ~$16/mes + reglas | ~$16/mes + LCU |
| **Uso típico** | APIs REST, Web apps | Bases de datos, gRPC, TCP |

## 🔄 Workflow de cambios

1. Edita `values.yaml`
2. Cambia `type: alb` o `type: nlb` según necesites
3. Configura la sección `alb:` o `nlb:` correspondiente
4. Commit y push
5. ArgoCD despliega automáticamente
