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

## ArgoCDのポート公開

ArgoCDはNodePortとして公開されています。外部から8080ポートでアクセスするには、kindクラスタの設定でポートマッピングが必要です。

### 既存のクラスタの場合

既存のkindクラスタでは、後からポートマッピングを追加できないため、以下のいずれかの方法を使用してください：

1. **kubectl port-forwardを使用**（一時的な解決策）:
```bash
kubectl --kubeconfig kubeconfig/edu-gpu-kind-portforward.yaml port-forward -n argocd svc/argocd-server 8080:80
```

2. **kindクラスタを再作成**（推奨）:
   - kindクラスタを削除して再作成すると、`ansible/roles/kind/templates/kind-config.yaml.j2`で設定されたポートマッピング（hostPort: 8080）が適用されます
   - その後、ArgoCDを再デプロイすると、8080ポートでアクセス可能になります

### 現在のNodePort確認

```bash
kubectl --kubeconfig kubeconfig/edu-gpu-kind-portforward.yaml get service argocd-server -n argocd
```
