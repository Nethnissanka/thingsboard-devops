trpipeline {
    agent any

    environment {
        PACKAGE_REPO      = "https://github.com/thingsboard/thingsboard/releases/download"
        SERVER_COMPOSE    = "docker-compose.yml"
        UPGRADE_COMPOSE   = "docker-compose.upgrade.yml"
        CURRENT_VERSION   = "4.0.0"  // Will be set dynamically
        MANUAL_VERSION    = "4.0.1"  // 🔧 Set to e.g., "4.0.1" to override auto-detect
    }

    stages {

        // stage('Detect Current Installed Version') {
        //     steps {
        //         script {
        //             echo '🔍 Detecting current ThingsBoard Docker image tag...'
        //             def image = sh(script: "docker inspect tb-server --format '{{ index .Config.Image }}'", returnStdout: true).trim()
        //             def tag = image.contains(":") ? image.split(":")[1] : "unknown"
        //             env.CURRENT_VERSION = tag
        //             if (env.CURRENT_VERSION == "unknown") {
        //                 error '❌ Could not determine current version!'
        //             }
        //             echo "📦 Current version: ${env.CURRENT_VERSION}"
        //         }
        //     }
        // }

        stage('Set Manual Version (Optional)') {
            steps {
                script {
                    echo '🔧 Checking for manual version override...'
                    // If MANUAL_VERSION is set, use it; otherwise, skip this stage
                    if (env.MANUAL_VERSION?.trim()) {
                        env.LATEST_VERSION = env.MANUAL_VERSION.trim()
                        echo "🔧 Manual version set to: ${env.LATEST_VERSION}"
                        env.SKIP_FETCH_LATEST = "true"
                    } else {
                        env.SKIP_FETCH_LATEST = "false"
                    }
                }
            }
        }

        stage('Fetch Latest GitHub Version') {
            when {
                expression { env.SKIP_FETCH_LATEST != "true" }
            }
            steps {
                script {
                    echo '🌐 Fetching latest release from GitHub...'
                    // Fetch latest release from GitHub API
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
                    echo '🔍 Comparing current version with latest release...'
                    if (!env.CURRENT_VERSION || !env.LATEST_VERSION) {
                        error '❌ Cannot compare versions — one or both are unknown!'
                    }
                    echo "📦 Current version: ${env.CURRENT_VERSION}, Latest version: ${env.LATEST_VERSION}"
                    // Compare versions
                    if (env.CURRENT_VERSION == env.LATEST_VERSION) {
                        // If versions match, skip upgrade
                        echo "✅ ThingsBoard is already up to date (v${env.CURRENT_VERSION})"
                        env.UPGRADE_REQUIRED = "false"
                    } else {
                        // If versions differ, set upgrade required
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
        stage('Cleanup') {
            when {
                expression { env.UPGRADE_REQUIRED == "true" }
            }
            steps {
                echo '🧹 Cleaning up RPMs …'
                sh "rm -f thingsboard-*.rpm"
            }
        }

        stage('Download RPM') {
            when {
                expression { env.UPGRADE_REQUIRED == "true" }
            }
            steps {
                script {
                    echo "📥 Downloading ThingsBoard RPM package..."
                    // Construct the RPM URL based on the latest version
                    def rpmUrl = "${PACKAGE_REPO}/v${env.LATEST_VERSION}/thingsboard-${env.LATEST_VERSION}.rpm"
                    echo "📥 Downloading RPM from: ${rpmUrl}"
                    // Download the RPM package
                    sh """
                        curl -L -o thingsboard-${env.LATEST_VERSION}.rpm ${rpmUrl}
                        mv thingsboard-${env.LATEST_VERSION}.rpm thingsboard.rpm
                        ls -lh thingsboard.rpm
                    """
                }
            }
        }

        stage('Stop Current Server') {
            when {
                expression { env.UPGRADE_REQUIRED == "true" }
            }
            steps {
                echo "🛑 Stopping existing ThingsBoard container"
                sh "docker compose -f ${env.SERVER_COMPOSE} down || true"
            }
        }

        stage('Build Upgrade Container') {
            when {
                expression { env.UPGRADE_REQUIRED == "true" }
            }
            steps {
                echo "🔧 Building Docker upgrade container"
                sh "docker compose -f ${env.UPGRADE_COMPOSE} build --no-cache"
                echo "🔧 Starting upgrade container"
            }
        }

        stage('Run Upgrade') {
            when {
                expression { env.UPGRADE_REQUIRED == "true" }
            }
            steps {
                echo "🚀 Running upgrade container (will auto-exit after upgrade)"
                // Run the upgrade container and wait for it to finish
                sh "docker compose -f ${env.UPGRADE_COMPOSE} up --abort-on-container-exit"
                echo "🔄 Upgrade container finished"
            }
        }

        stage('Rebuild Server Container') {
            when {
                expression { env.UPGRADE_REQUIRED == "true" }
            }
            steps {
                echo "🔄 Rebuilding updated server container"
                sh "docker compose -f ${env.SERVER_COMPOSE} build --no-cache"
                echo "🔄 Rebuilding complete"
            }
        }

        stage('Start ThingsBoard Server') {
            when {
                expression { env.UPGRADE_REQUIRED == "true" }
            }
            steps {
                echo "🚀 Starting upgraded ThingsBoard server"
                // docker rm -f tb-server || true
                sh '''
                    docker compose up -d --remove-orphans
                '''

                echo "🚀 ThingsBoard server started"

            }
        }

        stage('Verify ThingsBoard is Running') {
            when {
                expression { env.UPGRADE_REQUIRED == "true" }
            }
            steps {
                script {
                    echo "🔍 Verifying ThingsBoard is running"
                    // Wait for ThingsBoard to start up
                    sleep 60 // Adjust as needed for your environment
                    echo "🔍 Checking if ThingsBoard is up and running"
                    // Check if the application is responding
                    sh "docker compose -f ${env.SERVER_COMPOSE} ps"
                    echo "🔍 Checking HTTP status of ThingsBoard"
                    // Use curl to check if the application is responding
                    sleep 10 // Allow some time for the server to start
                    echo "🔍 Waiting for ThingsBoard to be ready"
                    sh "docker compose -f ${env.SERVER_COMPOSE} logs tb-server || true"
                    sleep 10 // Additional wait time for ThingsBoard to be fully operational


                    echo "🔍 Verifying application is up"
                    // Check if ThingsBoard is responding on HTTP
                    def code = sh(script: "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/login", returnStdout: true).trim()
                    if (code != "200") {
                        echo "❌ ThingsBoard is not responding correctly (HTTP ${code})"
                        // If not 200, fail the build
                        error "❌ Upgrade failed — HTTP status: ${code}"
                    } else {
                        // If 200, everything is fine
                        echo "✅ ThingsBoard is up and responding (HTTP 200)"
                    }
                }
            }
        }
    }

    post {
        success {
            script {
                echo "✅ Upgrade pipeline completed successfully!"
                // Print final version information
                echo "Current version: ${env.CURRENT_VERSION}"
                echo "Latest version: ${env.LATEST_VERSION}"
                // Check if an upgrade was performed
                if (env.UPGRADE_REQUIRED == "true") {
                    echo "🎉 ThingsBoard upgraded from v${env.CURRENT_VERSION} to v${env.LATEST_VERSION} successfully!"

                } else {
                    echo "✅ No upgrade needed. Still running v${env.CURRENT_VERSION}."

                }
            }
        }
        unstable {
            echo "⚠️ Pipeline completed with warnings. Please check logs."
        }
        aborted {
            echo "🚫 Pipeline was aborted. Please check logs and retry."
        }
        // Handle failure case
        failure {
            // If the pipeline fails, print a failure message
            echo "❌ Pipeline failed. Please check logs and retry."
        }
    }
}


