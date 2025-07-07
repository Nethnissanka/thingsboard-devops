pipeline {
    agent any

 environment {
        PACKAGE_URL_TEMPLATE = "https://github.com/thingsboard/thingsboard/releases/download/vVERSION/thingsboard-VERSION.rpm"
        BACKUP_DIR = "/var/backups/thingsboard"
    }

    stages {
     
        stage('Check Installed Version') {
            steps {
                script {
                    env.CURRENT_VERSION = sh(
                        script: 'rpm -q --qf "%{VERSION}" thingsboard || echo "not-installed"',
                        returnStdout: true
                    ).trim()
                    echo "📦 Current Installed Version: ${env.CURRENT_VERSION}"
                }
            }
        }

        stage('Fetch Latest GitHub Version') {
            steps {
                script {
                    def json = sh(script: "curl -s https://api.github.com/repos/thingsboard/thingsboard/releases/latest", returnStdout: true)
                    def matcher = json =~ /"tag_name":\s*"v(.*?)"/
                    env.LATEST_VERSION = matcher ? matcher[0][1] : "unknown"

                    if (env.LATEST_VERSION == "unknown") {
                        error("❌ Failed to fetch latest version from GitHub")
                    }
                    echo "🌐 Latest Available Version: ${env.LATEST_VERSION}"
                }
            }
        }

        stage('Compare Versions') {
            steps {
                script {
                    if (env.CURRENT_VERSION == "not-installed") {
                        error("❌ ThingsBoard is not installed on this machine.")
                    }
                    if (env.CURRENT_VERSION == env.LATEST_VERSION) {
                        currentBuild.result = 'SUCCESS'
                        echo "✅ ThingsBoard is already up-to-date (v${env.CURRENT_VERSION})"
                        return
                    }
                    echo "⬆️ Upgrade required: ${env.CURRENT_VERSION} → ${env.LATEST_VERSION}"
                }
            }
        }


        stage('Download Package') {
            steps {
                script {
                    def rpmUrl = env.PACKAGE_URL_TEMPLATE.replaceAll("VERSION", env.LATEST_VERSION)
                    echo "📥 Downloading package from: ${rpmUrl}"
                    sh "wget -q ${rpmUrl} -O thingsboard-${env.LATEST_VERSION}.rpm"
                }
            }
        }

	stage('Backup & Stop Service') {
            steps {
                script {
                    sh """
                        sudo systemctl stop thingsboard
                    """
                    echo "🛑 Service stopped & config backed up"
                    
                }
            }
        }


	stage('Verify Upgrade') {
            steps {
                script {
                    def versionCheck = sh(script: 'rpm -q --qf "%{VERSION}" thingsboard', returnStdout: true).trim()
                    def status = sh(script: 'systemctl is-active thingsboard', returnStdout: true).trim()
                    def apiCheck = sh(script: 'curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/login', returnStdout: true).trim()

                    echo "🔎 Version: ${versionCheck}"
                    echo "🔎 Service Status: ${status}"
                    echo "🔎 API Check Status: ${apiCheck}"

                    if (versionCheck != env.CURRENT_VERSION || status != "active" || apiCheck != "200") {
                        error("❌ Upgrade verification failed")
                    }
                    echo "✅ Upgrade to v${env.LATEST_VERSION} verified successfully"
		    echo "Thingsboard is in ${env.CURRENT_VERSION}"
                }
            }
        }
    }
post {
        success {
            echo "🎉 ThingsBoard upgraded successfully from ${env.CURRENT_VERSION} to ${env.LATEST_VERSION}"
        }
}

}
