function rek-minikube-auth() {
	kubectl config set-cluster rek-minikube --server=https://kubernetes.default.svc.cluster.local:8080
	kubectl config set-context rek-minikube --cluster=rek-minikube --namespace=default --user=rek-minikube
	kubectl config set-cluster rek-minikube --certificate-authority='/home/eddy/rek-minikube/ca.crt'

	#kubectl config use-context rek-minikube
	curl -s -X POST "https://keycloak.esnow.uk/auth/realms/master/protocol/openid-connect/token" \
		-d 'grant_type=password' \
		-d 'client_id=kubernetes_minikube' \
		-d 'client_secret=$(cat ~/.kube/.rek-minikube-client-secret)' \
		-d 'username=eddysnow@gmail.com' \
		-d 'password=$(cat ~/.kube/.rek-minikube-psw)' \
		-d 'scope=openid' \
		-d 'reponse_type=id_token' > ~/temp/jwt.token

	kubectl config set-credentials rek-minikube \
		--auth-provider=oidc \
		--auth-provider-arg=idp-issuer-url=https://keycloak.esnow.uk/auth/realms/master  \
		--auth-provider-arg=client-id=kubernetes_minikube  \
		--auth-provider-arg=client-secret=$(cat ~/.kube/.rek-minikube-client-secret) \
		--auth-provider-arg=refresh-token=$(jq -r '.refresh_token'< ~/temp/jwt.token) \
		--auth-provider-arg=id-token=$(jq -r '.id_token'< ~/temp/jwt.token)
}
