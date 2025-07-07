pipeline {
    agent any

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
    }
post {
        success {
            echo "🎉 ThingsBoard upgraded successfully from ${env.CURRENT_VERSION} to ${env.LATEST_VERSION}"
        }
}

}
