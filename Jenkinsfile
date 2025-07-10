pipeline {
    agent any

    environment {
        PACKAGE_URL_TEMPLATE = 'https://github.com/thingsboard/thingsboard/releases/download/vVERSION/thingsboard-VERSION.rpm'
        BACKUP_DIR = '/var/backups/thingsboard'
    }

    stages {
        stage('Detect Current Running Version') {
            steps {
                script {
                    echo '🔍 Detecting current running ThingsBoard Docker image version…'
                    def imageName = sh(
                        script: """
                            docker inspect tb-server-4.0.1 --format '{{ index .Config.Labels "thingsboard.version" }}'
                        """,
                        returnStdout: true
                    ).trim()
                    env.CURRENT_VERSION = imageName ?: 'unknown'
                    echo "📦 Current Docker version: ${env.CURRENT_VERSION}"
                }
            }
        }

        stage('Fetch Latest GitHub Version') {
            steps {
                script {
                    echo '🌐 Fetching latest release version from GitHub …'
                    def json = sh(script: 'curl -s https://api.github.com/repos/thingsboard/thingsboard/releases/latest', returnStdout: true)
                    def matcher = json =~ /"tag_name":\s*"v([0-9.]+)"/
                    env.LATEST_VERSION = matcher ? matcher[0][1] : 'unknown'

                    if (env.LATEST_VERSION == 'unknown') {
                        error '❌ Could not parse latest version from GitHub!'
                    }
                    echo "🌐 Latest available version: ${env.LATEST_VERSION}"
                }
            }
        }

        stage('Compare Versions & Decide') {
            steps {
                script {
                    echo '🔍 Comparing current Docker version with latest release…'
                    if (env.CURRENT_VERSION == env.LATEST_VERSION) {
                        echo "✅ ThingsBoard is already up-to-date (v${env.CURRENT_VERSION})"
                        env.UPGRADE_REQUIRED = "false"
                    } else {
                        echo "⬆️  Upgrade required: ${env.CURRENT_VERSION} ➜ ${env.LATEST_VERSION}"
                        env.UPGRADE_REQUIRED = "true"
                    }
                }
            }
        }

        stage('Download RPM') {
            when {
                expression { env.UPGRADE_REQUIRED == "true" }
            }
            steps {
                script {
                    def rpmUrl = env.PACKAGE_URL_TEMPLATE.replaceAll('VERSION', env.LATEST_VERSION)
                    echo "📥 Downloading RPM: ${rpmUrl}"
                    sh "wget -q ${rpmUrl} -O thingsboard-${env.LATEST_VERSION}.rpm"
                    sh 'ls -lh thingsboard-*.rpm'
                }
            }
        }

       
        
    }

    post {
        success {
            echo "🎉 Upgrade completed successfully!"
        }
        failure {
            echo "⚠️  Upgrade failed. Please check logs."
        }
    }
}
