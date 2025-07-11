pipeline {
    agent any

    environment {
        PACKAGE_REPO      = "https://github.com/thingsboard/thingsboard/releases/download"
        SERVER_COMPOSE    = "docker-compose.yml"
        UPGRADE_COMPOSE   = "docker-compose.upgrade.yml"
    }

    stages {
        stage('Detect Current Installed Version') {
            steps {
                script {
                    echo '🔍 Detecting current ThingsBoard Docker image tag...'
                    def image = sh(script: "docker inspect tb-server --format '{{ index .Config.Image }}'", returnStdout: true).trim()
                    def tag = image.contains(":") ? image.split(":")[1] : "unknown"
                    env.CURRENT_VERSION = tag
                    echo "📦 Current version: ${env.CURRENT_VERSION}"
                }
            }
        }

        stage('Fetch Latest GitHub Version') {
            steps {
                script {
                    echo '🌐 Fetching latest release from GitHub...'
                    def json = sh(script: 'curl -s https://api.github.com/repos/thingsboard/thingsboard/releases/latest', returnStdout: true)
                    def matcher = json =~ /"tag_name":\s*"v([0-9.]+)"/
                    env.LATEST_VERSION = matcher ? matcher[0][1] : 'unknown'
                    if (env.LATEST_VERSION == 'unknown') {
                        error '❌ Could not determine latest version!'
                    }
                    echo "🌐 Latest available version: ${env.LATEST_VERSION}"
                }
            }
        }

        stage('Compare Versions') {
            steps {
                script {
                    if (env.CURRENT_VERSION == env.LATEST_VERSION) {
                        echo "✅ ThingsBoard is already up to date (v${env.CURRENT_VERSION})"
                        env.UPGRADE_REQUIRED = "false"
                    } else {
                        echo "⬆️ Upgrade required: ${env.CURRENT_VERSION} ➜ ${env.LATEST_VERSION}"
                        env.UPGRADE_REQUIRED = "true"
                    }
                }
            }
        }

        stage('Skip Upgrade') {
            when {
                expression { env.UPGRADE_REQUIRED == "false" }
            }
            steps {
                echo "✅ Skipping upgrade — Already latest version."
            }
        }

        stage('Download RPM') {
            when {
                expression { env.UPGRADE_REQUIRED == "true" }
            }
            steps {
                script {
                    def rpmUrl = "${PACKAGE_REPO}/v${env.LATEST_VERSION}/thingsboard-${env.LATEST_VERSION}.rpm"
                    echo "📥 Downloading RPM from: ${rpmUrl}"
                    sh """
                        curl -L -o thingsboard-${env.LATEST_VERSION}.rpm ${rpmUrl}
                        mv thingsboard-${env.LATEST_VERSION}.rpm thingsboard.rpm
                        ls -lh thingsboard.rpm
                    """
                }
            }
        }

       
        stage('Verify ThingsBoard is Running') {
            when {
                expression { env.UPGRADE_REQUIRED == "true" }
            }
            steps {
                script {
                    echo "🔍 Verifying application is up"
                    def code = sh(script: "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/login", returnStdout: true).trim()
                    if (code != "200") {
                        error "❌ Upgrade failed — HTTP status: ${code}"
                    } else {
                        echo "✅ ThingsBoard is up and responding (HTTP 200)"
                    }
                }
            }
        }
    }

    post {
        success {
            script {
                if (env.UPGRADE_REQUIRED == "true") {
                    echo "🎉 ThingsBoard upgraded from v${env.CURRENT_VERSION} to v${env.LATEST_VERSION} successfully!"
                } else {
                    echo "✅ No upgrade needed. Still running v${env.CURRENT_VERSION}."
                }
            }
        }
        failure {
            echo "❌ Pipeline failed. Please check logs and retry."
        }
    }
}

