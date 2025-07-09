pipeline {
    agent any

    environment {
        PACKAGE_URL_TEMPLATE = 'https://github.com/thingsboard/thingsboard/releases/download/vVERSION/thingsboard-VERSION.rpm'
        BACKUP_DIR          = '/var/backups/thingsboard'
    }

    stages {

        stage('Check Installed Version of ThingsBoard') {
            steps {
                script {
                    echo '🔍 Detecting current installed version …'
                    env.CURRENT_VERSION = sh(
                        script: 'rpm -q --qf "%{VERSION}" thingsboard || echo "package thingsboard is not installed"',
                        returnStdout: true
                    ).trim()
                    echo "📦 Current version: ${env.CURRENT_VERSION}"
                }
            }
        }

        /* stage('Fetch Latest GitHub Version') {
            steps {
                script {
                    echo '🌐 Fetching latest release version from GitHub …'
                    def json    = sh(script: 'curl -s https://api.github.com/repos/thingsboard/thingsboard/releases/latest', returnStdout: true)
                    def matcher = json =~ /"tag_name":\s*"v([0-9.]+)"/
                    env.LATEST_VERSION = matcher ? matcher[0][1] : 'unknown'

                    if (env.LATEST_VERSION == 'unknown') {
                        error '❌ Could not parse latest version from GitHub!'
                    }
                    echo "🌐 Latest available version: ${env.LATEST_VERSION}"
                }
            }
        } */

        stage('Set Manual Version') {
            steps {
                script {
                    // Manually set the version instead of fetching from GitHub
                    echo '🔧 Manually setting ThingsBoard version to 4.0 …'
                    env.LATEST_VERSION = '4.0.0'
                    echo "✅ Manually set ThingsBoard version: ${env.LATEST_VERSION}"
                }
            }
        }

        stage('Compare Versions & Decide') {
            steps {
                script {
                    echo '🔍 Comparing installed version with latest version …'

                    if (env.CURRENT_VERSION == 'package thingsboard is not installed') {
                        error '❌ ThingsBoard is not installed on this node.'
                    }
                    echo "🔍 Current version: ${env.CURRENT_VERSION}"
                    echo "🔍 New version: ${env.LATEST_VERSION}"
                    

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

        stage('Skip Upgrade') {
            when {
                expression { env.UPGRADE_REQUIRED == "false" }
            }
            steps {
                echo "✅ Skipping upgrade — ThingsBoard already at v${env.CURRENT_VERSION}"
                echo '✅ No upgrade needed, exiting pipeline.'
            }
        }


        // stage('Compare Versions & Decide') {
        //     steps {
        //         script {
        //             echo '🔍 Comparing installed version with latest version …'

        //             if (env.CURRENT_VERSION == 'package thingsboard is not installed') {
        //                 error '❌ ThingsBoard is not installed on this node.'
        //             }
        //             echo "🔍 Current version: ${env.CURRENT_VERSION}"
        //             echo "🔍 Latest version: ${env.LATEST_VERSION}"
                    

        //             if (env.CURRENT_VERSION == env.LATEST_VERSION) {
        //                 currentBuild.result = 'SUCCESS'

        //                 // No need to proceed further, we are already on the latest version
        //                 echo "✅ ThingsBoard is already up-to-date (v${env.CURRENT_VERSION})"
        //                 echo '✅ No upgrade needed, exiting pipeline.'
        //                 return
        //             }
        //             echo "⬆️  Upgrade required: ${env.CURRENT_VERSION} ➜ ${env.LATEST_VERSION}"
        //         }
        //     }
        // }

        stage('Download RPM') {
            when {
                expression { env.UPGRADE_REQUIRED == "true" }
            }
            steps {
                script {
                    def rpmUrl = env.PACKAGE_URL_TEMPLATE
                                    .replaceAll('VERSION', env.LATEST_VERSION)

                    echo "📥 Downloading RPM: ${rpmUrl}"
                    sh "wget -q ${rpmUrl} -O thingsboard-${env.LATEST_VERSION}.rpm"

                    if (!fileExists("thingsboard-${env.LATEST_VERSION}.rpm")) {
                        error '❌ RPM download failed or file missing!'
                    }
                    sh 'ls -lh thingsboard-*.rpm'
                }
            }
        }

        stage('Backup & Stop Thingsboard Service') {
            when {
                expression { env.UPGRADE_REQUIRED == "true" }
            }
            steps {
                script {
                    echo '🔒 Backing up configuration …'
                    sh """
                        sudo mkdir -p ${env.BACKUP_DIR}
                        sudo cp -a /etc/thingsboard/conf/thingsboard.conf ${env.BACKUP_DIR}/thingsboard-${env.CURRENT_VERSION}.conf
                        sudo cp -a /etc/thingsboard/conf       ${env.BACKUP_DIR}/conf-${env.CURRENT_VERSION} || true
                    """
                    echo '🛑 Stopping ThingsBoard service …'
                    sh 'sudo systemctl stop thingsboard'
                }
            }
        }

        stage('Upgrade ThingsBoard') {
            when {
                expression { env.UPGRADE_REQUIRED == "true" }
            }
            steps {
                script {
                    echo "🔄 Performing upgrade to v${env.LATEST_VERSION}"
                    sh """
                        sudo rpm -Uvh thingsboard-${env.LATEST_VERSION}.rpm
                        sudo /usr/share/thingsboard/bin/install/upgrade.sh --fromVersion=${env.CURRENT_VERSION}
                        sudo systemctl start thingsboard
                    """
                }
            }
        }

        stage('Verify Upgrade') {
            when {
                expression { env.UPGRADE_REQUIRED == "true" }
            }
            steps {
                script {
                    echo '🔍 Verifying service health …'
                    def ver   = sh(script: 'rpm -q --qf "%{VERSION}" thingsboard', returnStdout:true).trim()
                    def stat  = sh(script: 'systemctl is-active thingsboard', returnStdout:true).trim()
                    // def http  = sh(script: 'curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/login', returnStdout:true).trim()

                    echo "🔎 Installed version : ${ver}"
                    echo "🔎 Systemd status    : ${stat}"
                    // echo "🔎 HTTP /login code  : ${http}"

                    if (ver != env.LATEST_VERSION || stat != 'active') {
                    //if (ver != env.LATEST_VERSION || stat != 'active' || http != '200') {
                        error '❌ Verification failed — triggering rollback.'
                    }
                    echo '✅ Upgrade verified!'
                }
            }
        }
    }

    post {

        success {
            script {
                if (env.UPGRADE_REQUIRED == "false") {
                    echo "✅ No upgrade was needed — ThingsBoard remains at v${env.CURRENT_VERSION}"
                } else {
                echo "🎉✅ Upgrade successful: ${env.CURRENT_VERSION} ➜ ${env.LATEST_VERSION}"
                }
            }
        }

        unstable {
            echo '⚠️  Build marked unstable. Review logs.'
        }

        failure {
            echo '⚠️  Upgrade failed, attempting rollback …'
            script {
                if (env.CURRENT_VERSION == 'package thingsboard is not installed') {
                    echo '❌ No previous install found — cannot rollback.'
                    return
                }

                def confBackupFile = "${env.BACKUP_DIR}/thingsboard-${env.CURRENT_VERSION}.conf"
                def dirBackup      = "${env.BACKUP_DIR}/conf-${env.CURRENT_VERSION}"

                if (!fileExists(confBackupFile) && !fileExists(dirBackup)) {
                    error "❌ No backup found — rollback impossible."
                }

                sh 'sudo systemctl stop thingsboard || true'

                if (fileExists(dirBackup)) {
                    sh """
                        sudo rm -rf /etc/thingsboard/conf
                        sudo cp -a ${dirBackup} /etc/thingsboard/conf
                    """
                } else {
                    sh "sudo cp -a ${confBackupFile} /etc/thingsboard/conf/thingsboard.conf"
                }

                sh 'sudo systemctl start thingsboard'

                /* verify rollback */
                def ver   = sh(script:'rpm -q --qf "%{VERSION}" thingsboard', returnStdout:true).trim()
                def stat  = sh(script:'systemctl is-active thingsboard', returnStdout:true).trim()
                // def http  = sh(script:'curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/login', returnStdout:true).trim()

                echo "🔄 After rollback -> version: ${ver}, status: ${stat}"

                if (ver != env.LATEST_VERSION || stat != 'active') {
                // if (ver != env.LATEST_VERSION || stat != 'active' || http != '200') {
                    error '❌ Rollback verification failed — manual intervention required.'
                }
                echo "✅ Rolled back to v${env.CURRENT_VERSION} successfully."
            }
        }
    }
}

