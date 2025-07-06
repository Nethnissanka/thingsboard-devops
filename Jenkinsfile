pipeline {
    agent any

    stages {
        stage('Check Current Version') {
            steps {
                script {
                    def currentVersion = sh(
                        script: 'rpm -q --qf "%{VERSION}" thingsboard || echo "not-installed"',
                        returnStdout: true
                    ).trim()
                    echo "🔍 Currently Installed ThingsBoard Version: ${currentVersion}"
                }
            }
        }

        stage('Fetch Latest GitHub Version') {
            steps {
                script {
                    def apiOutput = sh(
                        script: "curl -s https://api.github.com/repos/thingsboard/thingsboard/releases/latest",
                        returnStdout: true
                    ).trim()

                    def matcher = apiOutput =~ /"tag_name":\s*"v(.*?)"/
                    def latestVersion = matcher ? matcher[0][1] : "unknown"
                    echo "📦 Latest Available Version on GitHub: ${latestVersion}"
                }
            }
        }
    }
}
