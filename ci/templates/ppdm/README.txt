# RBAC yaml for containers that facilitate kubernetes backup from PowerProtect Data Manager
1. Run the following commands:  
   kubectl apply -f ppdm-discovery.yaml  
   kubectl apply -f ppdm-controller-rbac.yaml  
   kubectl get secrets -n powerprotect  
    
   *For Kubernetes version 1.24 and higher, the secret for ppdm-discovery-serviceaccount needs to be created manually*  

   kubectl apply -f - <<EOF  
   apiVersion: v1  
   kind: Secret  
   metadata:  
      name: ppdm-discovery-serviceaccount-token  
      namespace: powerprotect  
      annotations:  
        kubernetes.io/service-account.name: ppdm-discovery-serviceaccount  
  type: kubernetes.io/service-account-token  
  EOF  
  kubectl describe secret ppdm-discovery-serviceaccount-token-xxxxx -n powerprotect {Record the secret key}  
  kubectl cluster-info {Record the Kubernetes primary/control-plane endpoint}  
2. Go to the PowerProtect Data Manager UI and add the Kubernetes cluster as an Asset Source. Use the values for the secret key and the  Kubernetes primary/control-plan endpoint recorded from the previous commands.  
3. Once discovery status shows OK, run the following commands:  
  kubectl get ns {You should see powerprotect and velero-ppdm namespaces created}  
  kubectl get pods -n powerprotect {powerprotect controller pod should be running}  
  kubectl get pods -n velero-ppdm {velero pod should be running}  
