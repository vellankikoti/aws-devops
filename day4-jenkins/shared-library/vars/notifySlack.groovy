// Shared Library: Slack Notifications
def call(Map config = [:]) {
    def status = config.status ?: 'UNKNOWN'
    def channel = config.channel ?: '#devops-alerts'
    def color = status == 'SUCCESS' ? 'good' : 'danger'

    def message = """
        *${env.JOB_NAME}* - Build #${env.BUILD_NUMBER}
        *Status:* ${status}
        *Environment:* ${config.environment ?: 'unknown'}
        *Duration:* ${currentBuild.durationString}
        <${env.BUILD_URL}|View Build>
    """.stripIndent()

    try {
        slackSend(
            channel: channel,
            color: color,
            message: message
        )
    } catch (Exception e) {
        echo "Slack notification failed: ${e.message}"
    }
}
