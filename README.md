# Infrastructure

## kubectlの使い方

```bash
make decrypt-edu-gpu-kind-portforward
```

```bash
kubectl --kubeconfig kubeconfig/edu-gpu-kind-portforward.yaml get nodes
```

### kubeconfig/edu-gpu-kind-portforward.yamlを編集した時は

```bash
make encrypt-edu-gpu-kind-portforward
```
