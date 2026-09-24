pipeline {
    agent any

    stages {
        stage('Check Devices') {
            steps {
                bat 'adb devices'
            }
        }
        stage('Install Dependencies') {
            steps {
                bat 'pip install Appium-Python-Client selenium'
            }
        }
        stage('Run Appium Test') {
            steps {
                bat 'python "testing_files\\appium_test_open_first_screen.py"'
            }
        }
    }
}
