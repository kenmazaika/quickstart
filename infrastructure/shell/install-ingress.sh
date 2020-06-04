echo "Installing production ingress"
echo "> Generating"

echo "apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: hello-kubernetes-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-buffer-size: \"16k\"

spec:
  rules:
  - host: $INGRESS_HOST
    http:
      paths:
      - path: /api
        backend:
          serviceName: backend-$DEPLOYMENT_KEY-metropolis-quickstart-backend
          servicePort: 80
  - host: $INGRESS_HOST
    http:
      paths:
      - backend: # default backend
          serviceName: frontend-$DEPLOYMENT_KEY-metropolis-quickstart-frontend
          servicePort: 80" > infrastructure/terraform/ingress.yaml


echo "> Outputing"
cat infrastructure/terraform/ingress.yaml

echo "> Applying"
kubectl apply -f infrastructure/terraform/ingress.yaml

echo "> Finished"