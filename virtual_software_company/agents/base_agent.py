from dataclasses import dataclass, field
from typing import List, Optional, Dict
import uuid
import time

@dataclass
class Message:
    sender_id: str
    sender_role: str
    receiver_role: str
    content: str
    message_type: str = "DIRECT"  # DIRECT, BROADCAST, TASK
    timestamp: float = field(default_factory=time.time)
    id: str = field(default_factory=lambda: str(uuid.uuid4()))

class BaseAgent:
    def __init__(self, name: str, role: str, level: str, reports_to: Optional[str] = None):
        self.id = str(uuid.uuid4())
        self.name = name
        self.role = role  # e.g., "CEO", "Backend Developer"
        self.level = level  # e.g., "C-Suite", "Manager", "IC"
        self.reports_to = reports_to  # Role of the direct manager
        self.direct_reports: List[str] = [] # List of roles reporting to this agent
        self.inbox: List[Message] = []
        self.memory: List[str] = []  # Simple log of what happened
        
    def receive_message(self, message: Message):
        self.inbox.append(message)
        
    def process_inbox(self) -> List[Message]:
        """
        Process pending messages and return any new messages to send out.
        """
        outbox = []
        while self.inbox:
            msg = self.inbox.pop(0)
            print(f"[{self.role}] processing message from [{msg.sender_role}]: {msg.content[:50]}...")
            response = self._handle_message(msg)
            if response:
                if isinstance(response, list):
                    outbox.extend(response)
                else:
                    outbox.append(response)
        return outbox

    def _handle_message(self, message: Message) -> Optional[Message]:
        """
        Internal logic to handle a specific message.
        """
        self.memory.append(f"Received: {message.content}")
        
        # 1. Handle TASK Delegation
        if message.message_type == "TASK":
            if self.direct_reports:
                target_role = self.direct_reports[0]
                
                # Smart Routing Logic
                # 1. Priority: Architect for new feature specs
                if "implement" in message.content.lower() or "feature" in message.content.lower():
                     for r in self.direct_reports:
                         if "Architect" in r:
                             # Use simple keyword matching for domain
                             if "backend" in message.content.lower() and "Backend" in r: target_role = r; break
                             if ("frontend" in message.content.lower() or "ui" in message.content.lower()) and "Frontend" in r: target_role = r; break

                # 2. Secondary: Manager/Devs
                else: 
                     # Try to find a better match if possible
                    if ("database" in message.content.lower() or "sql" in message.content.lower()) and "Manager - Database Engineering" in self.direct_reports:
                        target_role = "Manager - Database Engineering"
                    elif "backend" in message.content.lower():
                        for r in self.direct_reports: 
                            if "Backend" in r and "Architect" not in r: target_role = r; break
                    elif "interface" in message.content.lower() or "ui" in message.content.lower():
                        for r in self.direct_reports: 
                            if ("Frontend" in r or "Design" in r) and "Architect" not in r: target_role = r; break
                
                return Message(
                    sender_id=self.id,
                    sender_role=self.role,
                    receiver_role=target_role,
                    content=f"DELEGATED: {message.content}",
                    message_type="TASK"
                )
            elif self.role.endswith("Architect"):
                 # Architect creates spec
                 return Message(
                    sender_id=self.id,
                    sender_role=self.role,
                    receiver_role=self.reports_to, # Send back to Director
                    content=f"SPECIFICATON READY for: {message.content}",
                    message_type="SPEC_READY"
                 )
            else:
                # I am an IC, I do the work
                
                # If I am a Dev, Start Code Review Process (Level 1)
                if "Dev" in self.role:
                    print(f"  >>> [{self.role}] Work finished. Requesting Peer Review.")
                    # Find a peer (any other Dev) - simple logic for MVP: broadcast to 'Backend Dev 2' if I am 'Backend Dev 1'
                    peer_role = "Backend Dev 2" if "1" in self.role else "Backend Dev 1"
                    if "Frontend" in self.role:
                        peer_role = "Frontend Dev 2" if "1" in self.role else "Frontend Dev 1"
                        
                    return Message(
                        sender_id=self.id,
                        sender_role=self.role,
                        receiver_role=peer_role,
                        content=f"REVIEW_REQUEST (Level 1): {message.content}",
                        message_type="REVIEW_REQUEST"
                    )
                else:
                    # Non-Dev ICs (e.g. QA doing a task) just finish it
                    return Message(
                        sender_id=self.id,
                        sender_role=self.role,
                        receiver_role=message.sender_role,
                        content=f"Task '{message.content[:20]}...' COMPLETED by {self.role}.",
                        message_type="DONE"
                    )
        
        # 2. Handle SPEC_READY from Architect
        elif message.message_type == "SPEC_READY":
             # Received Spec from Architect, now forward to Manager for implementation
             print(f"  >>> [{self.role}] RECEIVED SPEC from [{message.sender_role}]. Forwarding to Manager.")
             target_role = ""
             if "backend" in message.content.lower():
                  target_role = "Engineering Manager (Backend)"
             else:
                  target_role = "Engineering Manager (Frontend)"
                  
             return Message(
                sender_id=self.id,
                sender_role=self.role,
                receiver_role=target_role,
                content=f"IMPLEMENT: {message.content}",
                message_type="TASK"
             )

        # 3. Handle DONE Reports (Initiate Review)
        elif message.message_type == "DONE":
             # Special handling for Bug Fixes sent to Manager (Close Support Loop)
             if "Manager" in self.role and ("BUG_REPORT" in message.content or "URGENT FIX" in message.content):
                 print(f"  >>> [{self.role}] Bug Fix Deployed. Closing loop with Support.")
                 return Message(self.id, self.role, "Support Agent 1", message.content, "BUG_FIXED")

             # Fallback for others
             print(f"  >>> [{self.role}] ACKNOWLEDGED completion from [{message.sender_role}]")
             if self.reports_to:
                 return Message(sender_id=self.id, sender_role=self.role, receiver_role=self.reports_to, content=message.content, message_type="DONE")

        # 4. Handle REVIEW_REQUEST
        elif message.message_type == "REVIEW_REQUEST":
            current_level = 1
            if "Level 2" in message.content: current_level = 2
            elif "Level 3" in message.content: current_level = 3
            elif "Level 4" in message.content: current_level = 4
            
            print(f"  [REVIEW] {self.role} performing Level {current_level} review...")
            
            # Logic to approve and move to next level
            next_role = ""
            next_level_msg = ""
            
            if current_level == 1: # Peer -> DevOps (Level 2)
                next_role = "DevOps Engineer 1" # Simplified
                next_level_msg = message.content.replace("Level 1", "Level 2")
            elif current_level == 2: # DevOps -> Security (Level 3)
                next_role = "Security Engineer 1"
                next_level_msg = message.content.replace("Level 2", "Level 3")
            elif current_level == 3: # Security -> Architect (Level 4)
                # Infer Architect from context or default to Backend Arch
                next_role = "Backend Architect" 
                next_level_msg = message.content.replace("Level 3", "Level 4")
            elif current_level == 4: # Architect -> Approved
                # If this was a Bug Fix, we might want to flag it
                msg_type = "DEPLOY_APPROVED"
                content = f"DEPLOY_APPROVED: {message.content}"
                if "BUG_REPORT" in message.content or "URGENT FIX" in message.content:
                     # We keep it as DEPLOY_APPROVED but note it for the Manager to handle
                     pass

                return Message(
                    sender_id=self.id,
                    sender_role=self.role,
                    receiver_role=message.sender_role, 
                    content=content,
                    message_type=msg_type
                 )

            if next_role:
                 return Message(
                    sender_id=self.id,
                    sender_role=self.role,
                    receiver_role=next_role,
                    content=next_level_msg,
                    message_type="REVIEW_REQUEST"
                 )

        # 5. Handle DEPLOY_APPROVED
        elif message.message_type == "DEPLOY_APPROVED":
             print(f"  *** [{self.role}] DEPLOYMENT GREENLIT! Merging to Main. ***")
             
             # Smart Routing for Bug Fixes (Ensure Manager knows to close Support Ticket)
             if "BUG_REPORT" in message.content or "URGENT FIX" in message.content:
                 print(f"  >>> [{self.role}] Detected Bug Fix Deployment. Notifying Engineering Manager.")
                 # Ideally we'd know which manager, but for this scenario it's Backend
                 return Message(
                    sender_id=self.id,
                    sender_role=self.role,
                    receiver_role="Engineering Manager (Backend)",
                    content=f"Task Completed and Deployed: {message.content}",
                    message_type="DONE"
                 )

             # Now report DONE to Manager
             if self.reports_to:
                  return Message(
                    sender_id=self.id,
                    sender_role=self.role,
                    receiver_role=self.reports_to,
                    content=f"Task Completed and Deployed: {message.content}",
                    message_type="DONE"
                 )

        # 6. Simple Status Check
        elif "status report" in message.content.lower():
            return Message(
                sender_id=self.id,
                sender_role=self.role,
                receiver_role=message.sender_role,
                content=f"Report from {self.role}: All systems nominal. Working on assigned tasks."
            )
            
        # 7. Handle AUDIT_CHECK (TPM)
        elif message.message_type == "AUDIT_CHECK":
            # Simple check: if I have reports, I say "All Good". If I am an IC, I say "Done".
            # For this simulation, we'll assume the Recipient is the Manager who reports status.
            print(f"  [AUDIT] {self.role} received Audit Request from {message.sender_role}.")
            return Message(
                sender_id=self.id,
                sender_role=self.role,
                receiver_role=message.sender_role,
                content=f"Audit Status: {len(self.memory)} tasks processed.",
                message_type="AUDIT_REPORT"
            )

        # 8. Handle TASK_MISSING (Recovery Flow)
        elif message.message_type == "TASK_MISSING":
            print(f"  !!! [{self.role}] CRITICAL ALERT: {message.content} !!!")
            # If I am a Manager, I must delegate this immediately
            if self.direct_reports:
                # Urgent delegation
                target = self.direct_reports[0] # Just pick first valid one for now
                for r in self.direct_reports:
                    if "Backend" in message.content and "Backend" in r: target = r; break
                
                print(f"  >>> [{self.role}] Escalating MISSING TASK to [{target}]")
                return Message(
                    sender_id=self.id,
                    sender_role=self.role,
                    receiver_role=target,
                    content=f"URGENT_RECOVERY: {message.content}",
                    message_type="TASK"
                )
            
                return Message(
                    sender_id=self.id,
                    sender_role=self.role,
                    receiver_role=target,
                    content=f"URGENT_RECOVERY: {message.content}",
                    message_type="TASK"
                )
        
        # 9. Handle REQ_CHANGE (Requirement Scope Update)
        elif message.message_type == "REQ_CHANGE":
            print(f"  [SCOPE] {self.role} received Scope Update: {message.content}")
            
            # If Manager, propagate to team
            if self.direct_reports:
                print(f"  >>> [{self.role}] Broadcasting Scope Change to Team.")
                # For simplicity, broadcast to all directs (or specific ones if we had tracking)
                # Here we just pick the first relevant one or broadcast
                return Message(
                    sender_id=self.id,
                    sender_role=self.role,
                    receiver_role=self.direct_reports[0], # Simplified: just send to first report (Backend Dev 1 usually)
                    content=f"SCOPE_UPDATE: {message.content}",
                    message_type="REQ_CHANGE"
                )
            else:
                # IC acknowledges
                return Message(
                    sender_id=self.id,
                    sender_role=self.role,
                    receiver_role=message.sender_role,
                    content=f"Acknowledged Scope Change. Adjusting implementation for: {message.content}",
                    message_type="DIRECT"
                )
        
        # 10. Recruitment: HEADCOUNT_REQUEST Chain
        elif message.message_type == "HEADCOUNT_REQUEST":
            print(f"  [HIRING] {self.role} reviewing HEADCOUNT_REQUEST: {message.content}")
            
            # Chain: Manager -> Director -> VP Eng -> CTO -> CFO
            if "Manager" in self.role:
                 return Message(self.id, self.role, self.reports_to, message.content, "HEADCOUNT_REQUEST")
            elif "Director" in self.role:
                 return Message(self.id, self.role, self.reports_to, message.content, "HEADCOUNT_REQUEST")
            elif "VP Engineering" in self.role:
                 return Message(self.id, self.role, "CTO", message.content, "HEADCOUNT_REQUEST")
            elif "CTO" in self.role:
                 print(f"  [HIRING] CTO Approving tech need. Forwarding to CFO for Budget.")
                 return Message(self.id, self.role, "CFO", message.content, "BUDGET_CHECK")

        # 11. Recruitment: BUDGET_CHECK (CFO)
        elif message.message_type == "BUDGET_CHECK":
            print(f"  [FINANCE] CFO checking budget for: {message.content}")
            return Message(self.id, self.role, "VP People", message.content, "BUDGET_APPROVED")

        # 12. Recruitment: BUDGET_APPROVED (VP People)
        elif message.message_type == "BUDGET_APPROVED":
            print(f"  [HR] VP People received Budget Approval. Assigning Recruiter.")
            return Message(self.id, self.role, "Recruiter", message.content, "INITIATE_HIRING")

        # 13. Recruitment: INITIATE_HIRING (Recruiter)
        elif message.message_type == "INITIATE_HIRING":
            print(f"  [RECRUITING] Recruiter searching for candidate: {message.content}...")
            # Simulate finding a candidate immediately
            print(f"  [RECRUITING] Candidate Found! Onboarding started.")
            
            # Notify the original requesting Manager (We'll assume it's Engineering Manager (Backend) for this scenario)
            # In a real system, we'd parse the message content "Hiring for [Manager]"
            target_manager = "Engineering Manager (Backend)" 
            if "Frontend" in message.content: target_manager = "Engineering Manager (Frontend)"
            
            return Message(self.id, self.role, target_manager, f"New Hire Onboarded: {message.content}", "NEW_HIRE_ONBOARDED")

        # 14. Recruitment: NEW_HIRE_ONBOARDED (Manager)
        elif message.message_type == "NEW_HIRE_ONBOARDED":
             print(f"  [ONBOARDING] {self.role}: Welcome to the team! {message.content}")
             return None

        # 15. Process Health: PROCESS_HEALTH_CHECK (COO)
        elif message.message_type == "PROCESS_HEALTH_CHECK":
            print(f"  [OPS] {self.role} reporting status to COO...")
            
            # Simulate status based on role
            status_content = "All Processes Normal. 0 Pending."
            if "VP Engineering" in self.role:
                # Simulate a stuck approval
                status_content = "WARNING: 1 PENDING APPROVAL (Stuck > 3 Ticks). Awaiting Vendor Review."
            
            return Message(self.id, self.role, message.sender_role, status_content, "PROCESS_STATUS")

        # 16. Process Health: PROCESS_STATUS (COO)
        elif message.message_type == "PROCESS_STATUS":
             print(f"  [OPS] COO Analyzing Report from {message.sender_role}: {message.content}")
             
             if "Stuck" in message.content or "WARNING" in message.content:
                 print(f"  [OPS] COO Detected Bottleneck at [{message.sender_role}]. Issuing EXPEDITE Order.")
                 return Message(self.id, self.role, message.sender_role, "EXPEDITE: Immediately resolve pending items.", "EXPEDITE")
             else:
                 print(f"  [OPS] COO Verified Health of [{message.sender_role}]: OK.")
                 return None

        # 17. Process Health: EXPEDITE (VP)
        elif message.message_type == "EXPEDITE":
            print(f"  !!! [{self.role}] RECEIVED EXPEDITE ORDER FROM COO: {message.content}")
            print(f"  >>> [{self.role}] Escalating Priority. Approving Pending Items Immediately.")
            # Simulate unblocking process
            # We could return a confirmation or trigger next step, but for now we just log the action.
            return Message(self.id, self.role, "COO", "EXPEDITE COMPLETED: 1 Pending Item Approved.", "DONE")

        # 18. Customer Support: CUSTOMER_TICKET (Support Agent)
        elif message.message_type == "CUSTOMER_TICKET":
             print(f"  [SUPPORT] {self.role} received Customer Ticket: {message.content}")
             if "Error" in message.content or "Crash" in message.content:
                 print(f"  [SUPPORT] Triage: Critical Bug Detected. Escalating to Engineering.")
                 # Ascalate to Backend Manager for now
                 return Message(self.id, self.role, "Engineering Manager (Backend)", f"BUG_REPORT: {message.content}", "BUG_REPORT")
             else:
                 print(f"  [SUPPORT] Triage: General Inquiry. Replying to Customer.")
                 return None

        # 19. Customer Support: BUG_REPORT (Engineering Manager)
        elif message.message_type == "BUG_REPORT":
            print(f"  [BUG] {self.role} received Escalated Bug: {message.content}")
            # Delegate to a Developer (Reuse existing delegation or simple assignment)
            if self.direct_reports:
                target = self.direct_reports[0]
                print(f"  >>> [{self.role}] Assigning Bug Fix to {target}")
                return Message(self.id, self.role, target, f"URGENT FIX: {message.content}", "TASK")

        # 20. Customer Support: BUG_FIXED (Manager -> Support)
        elif message.message_type == "BUG_FIXED":
             print(f"  [BUG] Fix Confirmed by Engineering. Notifying Support.")
             # Assume original reporter was Support Agent 1 for this flow, or find it from context (omitted for brevity)
             return Message(self.id, self.role, "Support Agent 1", f"FIX DEPLOYED: {message.content}", "TICKET_RESOLVED")

        # 21. Customer Support: TICKET_RESOLVED (Support Agent)
        elif message.message_type == "TICKET_RESOLVED":
            print(f"  [SUPPORT] {self.role}: Closing Ticket. Emailing Customer: 'Your issue is resolved.'")
            return None

        # 22. Marketing: MARKETING_CAMPAIGN (CMO -> Directors)
        elif message.message_type == "MARKETING_CAMPAIGN":
             print(f"  [MARKETING] {self.role} received Campaign Brief: {message.content}")
             # Broadcast to Direct Reports (Directors)
             if self.direct_reports:
                 print(f"  >>> [{self.role}] Briefing Directors on Strategy.")
                 out_msgs = []
                 for report in self.direct_reports:
                     out_msgs.append(Message(self.id, self.role, report, f"EXECUTE PROMO: {message.content}", "POST_CONTENT"))
                 return out_msgs

        # 23. Marketing: POST_CONTENT (Directors -> Managers -> Specialists)
        elif message.message_type == "POST_CONTENT":
             print(f"  [CONTENT] {self.role} preparing content: {message.content}")
             # If Director, delegate to Managers
             if "Director" in self.role and self.direct_reports:
                 out_msgs = []
                 for report in self.direct_reports:
                     # Tailor message slightly
                     platform = "Social"
                     if "Community" in self.role: platform = "Community"
                     out_msgs.append(Message(self.id, self.role, report, f"Generate {platform} Assets for: {message.content}", "POST_CONTENT"))
                 return out_msgs
             
             # If Manager/IC, actually 'Post'
             print(f"  *** [{self.role}] POSTING TO CHANNEL: {message.content} ***")
             # Trigger Feedback Loop simulation
             return Message(self.id, self.role, self.role, "Check User Reactions", "COMMUNITY_EVENT")

        # 24. Community: COMMUNITY_EVENT (Self-Trigger for feedback)
        elif message.message_type == "COMMUNITY_EVENT":
             # Simulate reaction
             print(f"  [COMMUNITY] {self.role} monitoring live feed...")
             sentiment = "Positive"
             if "Twitch" in self.role: sentiment = "HYPE! POGGERS! (Very Positive)"
             elif "Discord" in self.role: sentiment = "Constructive Feedback: UI looks good but text is small."
             
             # Send Report to Product Manager
             target = "Product Manager"
             return Message(self.id, self.role, target, f"User Sentiment Analysis: {sentiment}", "SENTIMENT_REPORT")

        # 25. Product Feedback: SENTIMENT_REPORT (Community -> Product Manager)
        elif message.message_type == "SENTIMENT_REPORT":
             print(f"  [PRODUCT] {self.role} analyzing User Feedback: {message.content}")
             if "Constructive" in message.content or "Negative" in message.content:
                 print(f"  >>> [{self.role}] Creating Improvement Story based on Feedback.")
                 # Could trigger a new task here
             return None

        # 26. Design: ASSET_REQUEST (VP -> Creative Director -> Studio)
        elif message.message_type == "ASSET_REQUEST":
             print(f"  [DESIGN] {self.role} received Request: {message.content}")
             if "Creative Director" in self.role:
                 # Delegate to Studio
                 print(f"  >>> [{self.role}] Commissioning Creative Studio.")
                 return [
                     Message(self.id, self.role, "Brand Designer", f"Create Assets: {message.content}", "TASK"),
                     Message(self.id, self.role, "Motion Designer", f"Animate Assets: {message.content}", "TASK")
                 ]

        # 27. Design: USER_RESEARCH (Unsolicited or Directed)
        elif message.message_type == "USER_RESEARCH":
             print(f"  [RESEARCH] {self.role} conducting study: {message.content}...")
             print(f"  [RESEARCH] Interviewing 5 Users... Synthesizing Data...")
             # Output findings
             findings = "Key Finding: Users are confused by the navigation bar."
             return Message(self.id, self.role, "Product Manager", f"Research Report: {findings}", "RESEARCH_FINDINGS")

        # 28. Product: RESEARCH_FINDINGS (Researcher -> PM)
        elif message.message_type == "RESEARCH_FINDINGS":
             print(f"  [PRODUCT] {self.role} received Research Data: {message.content}")
             print(f"  >>> [{self.role}] Updating Roadmap. Triggering Design Review.")
             return Message(self.id, self.role, "Design Lead", f"Redesign Navigation based on: {message.content}", "DESIGN_REVIEW")

        # 29. Design: DESIGN_REVIEW (PM -> Design Lead -> Designers)
        elif message.message_type == "DESIGN_REVIEW":
             print(f"  [DESIGN] {self.role} Reviewing Requirements: {message.content}")
             if "Lead" in self.role:
                 print(f"  >>> [{self.role}] Assigning Tasks to Product Designers.")
                 return [
                     Message(self.id, self.role, "Interaction Designer (IxD)", f"Wireframe: {message.content}", "TASK"),
                     Message(self.id, self.role, "Visual Designer (UI)", f"High-Fi Mockup: {message.content}", "TASK")
                 ]
        
        return None

    def __repr__(self):
        return f"<Agent {self.role} ({self.name})>"
