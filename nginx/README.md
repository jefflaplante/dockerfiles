## Dockerfile for NGINX 

# Create configmap from NGINX config file

```shell
kubectl create configmap nginx --from-file=default.conf
```
