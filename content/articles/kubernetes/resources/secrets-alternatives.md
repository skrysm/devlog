---
title: Alternatives for Kubernetes Secrets
description: Overview of more secure alternatives to Secrets in Kubernetes
date: 2025-08-05
topics:
- kubernetes
- security
---

Kubernetes [Secrets](secrets.md) have a major downside: **they can't be securely stored in Git**.

There are basically two flavors of how to solve this problem:

1. Store secrets **encrypted in Git.**
1. Store secrets **in an external KMS** (Key Management Service).

Both flavors usually require you to run a controller/operator in your cluster or CI/CD platform that automatically decrypts/downloads the secrets. The decrypted/downloaded secrets are then converted into regular Kubernetes Secrets or provided as volumes that can be consumed by Pods.

**Flavor 1** (store in Git) seems to be the natural choice - this way your whole desired cluster state can live in Git. Comparing to flavor 2:

* *Infrastructure* - No additional infrastructure (external KMS) needed.
* *Key Rotation* - You need to decide whether to change your encryption key (and thus re-encrypt your secrets) periodically - which can be a lot of work. Also, the decision itself - whether to rotate or not - may not be straight forward. Note also that you can't just re-encrypt the secrets in your cluster - you also need to update the secret files in Git.
* *Backup* - You need to backup the encryption key.
  * Sealed Secrets creates the encryption key for you - and creates a new key every 30 days. So you need to know how to find and backup these keys.
  * With SOPS, *you* control the key - so backup is easier.
* *Future-proofing* - Development on the two most popular solutions (Sealed Secrets and SOPS) seem to have stalled - which may not make them future-proof.

**Flavor 2** (store in KMS) is often a good alternative because the cloud provider that hosts your Kubernetes cluster most likely also provides you with a KMS. Comparing to flavor 1:

* *Infrastructure* - You need an external KMS. They either cost money or you need to self-host one (e.g. Vault) which comes with its own complexity.
* *Key Rotation* - Your KMS does the encryption key rotation - and re-encryption of your secrets - for you.
  * For on-premises clusters, you somehow need to get the credentials for the KMS into your cluster. While the problem this is similar to the encryption key rotation in flavor 1, there is one major difference: When you rotate the credentials for your KMS, you don't need to re-encrypt all your secrets.
* *Backup*
  * Cloud KMS - Cloud providers do the backups for you and ensure high availability for the KMS. No manual backup needed.
  * On-premises KMS - Have usually a dedicated backup functionality built in.
* *Future-proofing* - The industry seems to be leaning toward this option - especially External-Secrets. Thus, this flavor seems to be more future-proof than flavor 1.

On this page I want to show a couple of alternatives that fix this problem:

* [**Sealed Secrets**](https://github.com/bitnami-labs/sealed-secrets)
  * Secrets are stored encrypted in a custom `SealedSecret` resource which can safely be stored in Git.
  * A controller in the Kubernetes cluster automatically decrypts them and converts them into a regular Kubernetes Secret.
  * The decryption key is automatically created and stored in the cluster. By default, each cluster has its own decryption key, thus `SealedSecrets` only work for *that* cluster and not for any other cluster.
  * No external key store is required or supported for storing the decryption key.
* [**Mozilla SOPS**](https://github.com/getsops/sops)
  * Kubernetes-independent, generic secrets encryption tool that encrypts values (but not the keys) in JSON or YAML files (or a few other file types).
  * SOPS support both local decryption keys (Age, PGP, GnuPG), decryption keys stored in remote key vault (GCP KMS, AWS KMS, Azure Key Vault), and transit decryption (i.e. decryption done by external tools; HashiCorp Vault).
  * Secrets format on disk depends on the Kubernetes operator:
    * GitOps operator (e.g. [FluxCD](https://fluxcd.io/flux/guides/mozilla-sops/)) - decrypts the SOPS encrypted files before applying them as resources to the Kubernetes cluster.
      * Notably, [ArgoCD cautions against this mode](https://argo-cd.readthedocs.io/en/stable/operator-manual/secret-management/#argo-cd-manifest-generation-based-secret-management).
    * [SOPS Secrets Operator](https://github.com/isindir/sops-secrets-operator) - uses a custom resource (`SopsSecret`) like "Sealed Secrets" and converts them into regular Kubernetes Secrets.
* [**External-Secrets**](https://external-secrets.io/)
* [**Vault Secrets Operator**](https://developer.hashicorp.com/vault/docs/deploy/kubernetes/vso)
* [**Kubernetes Secrets Store CSI Driver**](https://github.com/kubernetes-sigs/secrets-store-csi-driver)

> [!NOTE]
> All of these solutions are **third-party solutions**; i.e. not built-in into Kubernetes.

## Sealed Secrets

You install Sealed Secrets with:

```sh
# Kubernetes controller
$ helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
$ helm install sealed-secrets -n kube-system --set-string fullnameOverride=sealed-secrets-controller sealed-secrets/sealed-secrets
# Client-side tool
$ brew install kubeseal
```

**To create and use an encrypted secret:**

1. Create regular Kubernetes Secret YAML on disk:

   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: db-credentials
   type: Opaque
   stringData:
     password: super-secret-password222
   ```

1. Encrypt secret with `kubeseal` (automatically retrieves the encryption key from the Kubernetes cluster):

   ```sh
   kubeseal --format yaml < secret-base.yml > secret-sealed.yml
   ```

   This will result in something like this:

   ```yaml
   ---
   apiVersion: bitnami.com/v1alpha1
   kind: SealedSecret
   metadata:
     creationTimestamp: null
     name: db-credentials
     namespace: testing
   spec:
     encryptedData:
       password: AgA46koV3/Lg/I1VtLbMKNBUfx73ss/O66Up75...
     template:
       metadata:
         creationTimestamp: null
         name: db-credentials
         namespace: testing
       type: Opaque
   ```

1. You delete the un-encrypted file.
1. You apply the resource to your cluster:

   ```sh
   kubectl apply -f secret-sealed.yml
   ```

1. You use the Secret like any other Secret.

> [!WARNING]
> For security reasons, Sealed Secrets can't be renamed or moved to a different [Namespace](namespaces.md) by default. However, this restriction can be relaxed. See [scopes](https://github.com/bitnami-labs/sealed-secrets?tab=readme-ov-file#scopes) for more details.

### Sealing Key Rotation

The Sealed Secret controller will periodically (every 30 days, by default) create a new sealing key. From this moment, this new key (actually, a public-private-key pair) will be used to encrypt new Sealed Secrets.

However, **existing Sealed Secrets will *not* be re-encrypted with the new key**. (This wouldn't make much sense, if you think about it, because the source for these keys is likely a Git repository and the controller doesn't have access to it.)

Because of this, the Sealed Secret controller **will keep all previous keys around** in the cluster and **never delete them**.

This has a few implications:

* Over time, the controller will clutter your cluster with sealing keys.
* For any given key, it's *not* (easily) possible to see if it was actually used to encrypt a Sealed Secret.
* You need to backup *all* sealing keys because you can't know which ones have been used.

To backup all sealing keys, run:

```sh
kubectl -n kube-system get secret -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > backup.yaml
```

> [!WARNING]
> The contents of the backup are **highly sensitive**! Make sure to keep them safe.

### Manual Key Rotation

If your current sealing key gets compromised (e.g. accidentally checked in into Git), you need to manually rotate the sealing key.

Unfortunately, manually creating a new sealing key seems to be very complicated.

There are [some instructions](https://github.com/bitnami-labs/sealed-secrets?tab=readme-ov-file#early-key-renewal) on how to do this but it's not really clear how to do this exactly.

There are some instructions on how to [bring your own certificate](https://github.com/bitnami-labs/sealed-secrets/blob/main/docs/bring-your-own-certificates.md). This could be used.

You could delete the compromised sealing key and then restart the Sealed Secrets controller Pod - but it's unclear if this would affect any existing Sealed Secrets in the cluster (as the controller may no longer be able to decrypt them). You could be fine if the controller only decrypts them once and then stores the decrypted version in a regular Kubernetes Secret.

### Recommendation

Sealed Secrets are easy to installed and fairly easy to use.

They allow you to store your cluster secrets in a secure way so that you can store your whole cluster state in Git.

However, you should only use them if you can easily recreate the Sealed Secrets (i.e. because you can get the actual secrets from somewhere else).

If not, disaster recovery can get quite complicated because of how the sealing keys work and are stored.

To quote the developers:

> [...] treating sealed-secrets as long term storage system for secrets is not the recommended use case [...] ([source](https://github.com/bitnami-labs/sealed-secrets?tab=readme-ov-file#can-i-decrypt-my-secrets-offline-with-a-backup-key))
