export function calculateSignalScore(
  eventType: string,
  metadata?: Record<string, any>,
): number {
  // Base scores by event type
  const baseScores: Record<string, number> = {
    email_sent: 0.1,
    email_opened: 0.3,
    email_clicked: 0.6,
    meeting_booked: 0.8,
    call_made: 0.5,
    demo_completed: 0.9,
  };

  let score = baseScores[eventType] || 0.1;

  // Apply modifiers based on metadata
  if (metadata) {
    // Increase score if response time is quick
    if (metadata.responseTimeHours && metadata.responseTimeHours < 24) {
      score += 0.1;
    }

    // Increase score for multiple interactions
    if (metadata.interactionCount && metadata.interactionCount > 3) {
      score += 0.15;
    }

    // Cap at 1.0
    score = Math.min(score, 1.0);
  }

  return parseFloat(score.toFixed(2));
}
