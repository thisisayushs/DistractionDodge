import Foundation


struct AppMessages {
    static let messages = [
        "Messages": [
            "Mom: Are you coming for dinner?",
            "Dad: Just landed at the airport",
            "John: Let's meet for coffee",
            "Sara: Don't forget about tomorrow",
            "Alex: Check out this link"
        ],
        "Calendar": [
            "Team Meeting in 15 minutes",
            "Doctor's Appointment at 2 PM",
            "Project Deadline Tomorrow",
            "Lunch with colleagues",
            "Weekly Review at 4 PM"
        ],
        "Mail": [
            "Weekly Report Due Today",
            "New email from HR Department",
            "Meeting agenda updated",
            "Invoice received",
            "Travel itinerary confirmed"
        ],
        "Reminders": [
            "Pick up groceries",
            "Call the dentist",
            "Pay electricity bill",
            "Submit expense report",
            "Book flight tickets"
        ],
        "FaceTime": [
            "Missed call from Dad",
            "Mom wants to FaceTime",
            "Incoming call from John",
            "Video call request",
            "Group call from Family"
        ],
        "Weather": [
            "Rain expected in your area",
            "Temperature dropping tonight",
            "High winds alert",
            "Clear skies this afternoon",
            "Storm warning for tonight"
        ],
        "Photos": [
            "New Memory: Last Summer",
            "Photos from your trip",
            "Sharing suggestion: Beach Day",
            "New shared album invite",
            "Featured photos selected"
        ],
        "Clock": [
            "Alarm for 7:00 AM",
            "Timer completed",
            "Bedtime in 30 minutes",
            "Wake up alarm set",
            "Timer paused"
        ]
    ]
    
    static func randomMessage(for app: String) -> String {
        return messages[app]?.randomElement() ?? "New Notification"
    }
}
