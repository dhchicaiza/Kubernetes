# Solución al Error: kubectl not found

Si encuentras el error `zsh: command not found: kubectl`, tienes dos opciones:

## Opción 1: Usar kubectl de Minikube (Recomendado - Sin instalación)

Minikube incluye su propia versión de kubectl. Simplemente reemplaza `kubectl` con `minikube kubectl --` en todos los comandos:

```bash
# En lugar de:
kubectl get pods

# Usa:
minikube kubectl -- get pods
```

### Crear un alias para facilitar el uso

Agrega esto a tu `~/.zshrc`:

```bash
alias kubectl="minikube kubectl --"
```

Luego recarga tu configuración:

```bash
source ~/.zshrc
```

Ahora puedes usar `kubectl` normalmente:

```bash
kubectl get pods
kubectl apply -f db-config.yaml
kubectl get services
```

## Opción 2: Instalar kubectl

### Arch Linux

```bash
sudo pacman -S kubectl
```

### Ubuntu/Debian

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### macOS

```bash
brew install kubectl
```

### Verificar la instalación

```bash
kubectl version --client
```

## Usar los Scripts de Despliegue

Los scripts incluidos (`deploy.sh`, `status.sh`, `cleanup.sh`) ya usan `minikube kubectl --`, por lo que funcionarán sin necesidad de instalar kubectl por separado:

```bash
./deploy.sh    # Despliega la aplicación
./status.sh    # Muestra el estado
./cleanup.sh   # Limpia los recursos
```

## Contexto de kubectl

Minikube configura automáticamente el contexto de kubectl. Puedes verificarlo con:

```bash
# Con kubectl instalado
kubectl config current-context

# O con minikube
minikube kubectl -- config current-context
```

Debería mostrar: `minikube`

## Comandos Comunes

Aquí algunos comandos traducidos para usar con minikube:

| Con kubectl instalado | Con minikube kubectl |
|-----------------------|----------------------|
| `kubectl get pods` | `minikube kubectl -- get pods` |
| `kubectl apply -f file.yaml` | `minikube kubectl -- apply -f file.yaml` |
| `kubectl logs pod-name` | `minikube kubectl -- logs pod-name` |
| `kubectl describe pod pod-name` | `minikube kubectl -- describe pod pod-name` |
| `kubectl exec -it pod-name -- bash` | `minikube kubectl -- exec -it pod-name -- bash` |
| `kubectl get services` | `minikube kubectl -- get services` |
| `kubectl delete -f file.yaml` | `minikube kubectl -- delete -f file.yaml` |

## Recomendación

Para este proyecto, **usa los scripts de despliegue** (`deploy.sh`, `status.sh`, `cleanup.sh`) que ya tienen todo configurado correctamente. Si necesitas ejecutar comandos kubectl directamente, crea el alias mencionado arriba.
