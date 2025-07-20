pipeline {
  agent any
  environment {
    SSH_USER = credentials('ssh_user')
    PRIVKEY  = credentials('ssh_privkey')
    WIN_USER = credentials('win_user')
    WIN_PASS = credentials('win_pass')
  }
  stages {
    stage('Checkout repo') {
      steps {
        checkout scm
      }
    }
    stage('Pre-check CSV Format') {
      steps {
        echo '🔎 Validating Linux and Windows CSV formats...'
        sh 'chmod +x scripts/validate_csv_format.sh'
        sh 'scripts/validate_csv_format.sh csv/linux_targets.csv'
        sh 'scripts/validate_csv_format.sh csv/windows_targets.csv'
      }
    }
    stage('Linux wave') {
      steps {
        echo '🚀 Running Linux rollout...'
        sh '''
          chmod +x scripts/rollout_linux.sh
          scripts/rollout_linux.sh csv/linux_targets.csv "$SSH_USER" "$PRIVKEY"
        '''
      }
    }
    stage('Windows wave') {
      when {
        expression { return false } // Temporarily disabled until finalized
      }
      steps {
        echo '🚀 Running Windows rollout...'
      }
    }
  }
  post {
    failure {
      echo '❌ Pipeline failed. Check logs for details.'
    }
    success {
      echo '✅ Pipeline succeeded.'
    }
  }
}
