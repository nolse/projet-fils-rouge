// ============================================================
// Jenkinsfile — Pipeline CI/CD ic-webapp — IC Group
// Déclenché automatiquement à chaque push sur le repo
// ou manuellement depuis l'interface Jenkins
//
// Étapes :
//   1. Checkout          — récupération du code source
//   2. Read Version      — lecture version/URLs depuis releases.txt
//   3. Build             — construction de l'image Docker
//   4. Test              — vérification que le container démarre
//   5. Push              — push de l'image sur Docker Hub
//   6. Generate Inventory— génération dynamique de hosts.yml
//   7. Deploy            — déploiement via Ansible sur les 3 serveurs
// ============================================================

pipeline {
    agent any

    // --------------------------------------------------------
    // Variables globales du pipeline
    // La version est lue depuis releases.txt et utilisée
    // comme tag de l'image Docker
    // IPs des serveurs stockées dans Jenkins Global Variables
    // --------------------------------------------------------
    environment {
        // Identifiants Docker Hub stockés dans Jenkins Credentials
        DOCKER_HUB_CREDS = credentials('docker-hub-credentials')
        DOCKER_HUB_USER  = 'alphabalde'
        IMAGE_NAME       = 'ic-webapp'
        // Clé SSH pour Ansible — stockée dans Jenkins Credentials
        ANSIBLE_KEY      = credentials('ansible-ssh-key')
    }

    stages {

        // ----------------------------------------------------
        // Étape 1 : Récupération du code source
        // ----------------------------------------------------
        stage('Checkout') {
            steps {
                echo '��� Récupération du code source...'
                checkout scm
            }
        }

        // ----------------------------------------------------
        // Étape 2 : Lecture de la version depuis releases.txt
        // La version sera utilisée comme tag de l'image Docker
        // ----------------------------------------------------
        stage('Read Version') {
            steps {
                echo '��� Lecture de la version depuis releases.txt...'
                script {
                    // Extraction via awk (même mécanisme que le Dockerfile)
                    env.APP_VERSION = sh(
                        script: "awk '/version/{print \$2}' releases.txt",
                        returnStdout: true
                    ).trim()
                    env.ODOO_URL = sh(
                        script: "awk '/ODOO_URL/{print \$2}' releases.txt",
                        returnStdout: true
                    ).trim()
                    env.PGADMIN_URL = sh(
                        script: "awk '/PGADMIN_URL/{print \$2}' releases.txt",
                        returnStdout: true
                    ).trim()
                    echo "Version détectée   : ${env.APP_VERSION}"
                    echo "ODOO_URL           : ${env.ODOO_URL}"
                    echo "PGADMIN_URL        : ${env.PGADMIN_URL}"
                }
            }
        }

        // ----------------------------------------------------
        // Étape 3 : Build de l'image Docker
        // Tag = version lue dans releases.txt
        // ----------------------------------------------------
        stage('Build') {
            steps {
                echo "��� Build de l'image ${IMAGE_NAME}:${env.APP_VERSION}..."
                sh """
                    docker build \\
                        --build-arg ODOO_URL=${env.ODOO_URL} \\
                        --build-arg PGADMIN_URL=${env.PGADMIN_URL} \\
                        -t ${DOCKER_HUB_USER}/${IMAGE_NAME}:${env.APP_VERSION} .
                """
            }
        }

        // ----------------------------------------------------
        // Étape 4 : Test du container
        // Lance un container, vérifie qu'il répond sur le port 8085
        // puis le supprime
        // ----------------------------------------------------
        stage('Test') {
            steps {
                echo '��� Test du container ic-webapp...'
                sh """
                    docker run -d \\
                        --name test-ic-webapp \\
                        -p 8085:8080 \\
                        -e ODOO_URL=${env.ODOO_URL} \\
                        -e PGADMIN_URL=${env.PGADMIN_URL} \\
                        ${DOCKER_HUB_USER}/${IMAGE_NAME}:${env.APP_VERSION}
                    sleep 5
                    docker ps | grep test-ic-webapp
                    curl -sf http://localhost:8085 | grep -i "IC GROUP" && echo "✅ Test OK" || echo "❌ Test FAILED"
                """
            }
            post {
                always {
                    // Nettoyage du container de test dans tous les cas
                    sh '''
                        docker stop test-ic-webapp || true
                        docker rm   test-ic-webapp || true
                    '''
                }
            }
        }

        // ----------------------------------------------------
        // Étape 5 : Push de l'image sur Docker Hub
        // Tag version + tag latest
        // Guillemets simples intentionnels : évite l'interpolation
        // Groovy sur DOCKER_HUB_CREDS_PSW (sécurité credentials)
        // ----------------------------------------------------
        stage('Push') {
            steps {
                echo "��� Push de l'image sur Docker Hub..."
                sh '''
                    echo $DOCKER_HUB_CREDS_PSW | docker login -u $DOCKER_HUB_CREDS_USR --password-stdin
                    docker push $DOCKER_HUB_USER/$IMAGE_NAME:$APP_VERSION
                    docker tag  $DOCKER_HUB_USER/$IMAGE_NAME:$APP_VERSION \
                                $DOCKER_HUB_USER/$IMAGE_NAME:latest
                    docker push $DOCKER_HUB_USER/$IMAGE_NAME:latest
                '''
            }
        }

        // ----------------------------------------------------
        // Étape 6 : Génération de l'inventaire Ansible
        // hosts.yml est gitignore — généré dynamiquement
        // depuis les IPs stockées dans Jenkins Global Variables
        // (JENKINS_IP, WEBAPP_IP, ODOO_IP)
        // ----------------------------------------------------
        stage('Generate Inventory') {
            steps {
                echo '��� Génération de l inventaire Ansible...'
                sh '''
                    cat > inventaire/hosts.yml << EOF
---
all:
  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: $ANSIBLE_KEY
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
  children:
    jenkins:
      hosts:
        jenkins_server:
          ansible_host: $JENKINS_IP
    webapp:
      hosts:
        webapp_server:
          ansible_host: $WEBAPP_IP
    odoo:
      hosts:
        odoo_server:
          ansible_host: $ODOO_IP
EOF
                '''
            }
        }

        // ----------------------------------------------------
        // Étape 7 : Déploiement via Ansible
        // Lance le playbook principal sur les 3 serveurs
        // Guillemets simples intentionnels : évite l'interpolation
        // Groovy sur ANSIBLE_KEY (sécurité credentials)
        // ----------------------------------------------------
        stage('Deploy') {
            steps {
                echo '��� Déploiement via Ansible...'
                sh '''
                    chmod 600 $ANSIBLE_KEY
                    ansible-playbook \
                        -i inventaire/hosts.yml \
                        --private-key=$ANSIBLE_KEY \
                        -e "webapp_image=$DOCKER_HUB_USER/$IMAGE_NAME:$APP_VERSION" \
                        -e "odoo_url=$ODOO_URL" \
                        -e "pgadmin_url=$PGADMIN_URL" \
                        playbook.yml
                '''
            }
        }

    }  // ← ferme stages

    // --------------------------------------------------------
    // Notifications post-pipeline
    // --------------------------------------------------------
    post {
        success {
            echo "✅ Pipeline terminé avec succès — version ${env.APP_VERSION} déployée !"
        }
        failure {
            echo "❌ Pipeline en échec — vérifiez les logs ci-dessus."
        }
        always {
            // Nettoyage des images Docker non utilisées pour libérer l'espace
            sh 'docker image prune -f || true'
        }
    }

}  // ← ferme pipeline
