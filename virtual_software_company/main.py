import time
import random
from agents.registry import create_company_agents
from core.communication import CommunicationBus, Message

def main():
    print("Initializing Virtual Software Company...")
    
    # 1. Initialize Communication Bus
    bus = CommunicationBus()
    
    # 2. Create Agents
    agents = create_company_agents()
    print(f"Created {len(agents)} agents.")
    
    # 3. Register Agents with Bus and Link Hierarchy
    for agent in agents:
        bus.register_agent(agent)
    
    # Link Hierarchy (populate direct_reports)
    for agent in agents:
        if agent.reports_to:
            manager = bus.role_map.get(agent.reports_to)
            if manager:
                manager.direct_reports.append(agent.role)
            else:
                print(f"Warning: Manager '{agent.reports_to}' not found for '{agent.role}'")

    print("\n--- Simulation Started ---\n")
    
    # 4. Trigger: CTO starts a feature request
    cto = bus.role_map["CTO"]
    print(f"Triggering Feature Request from {cto.role}...")
    bus.route_message(Message(
        sender_id=cto.id,
        sender_role=cto.role,
        receiver_role=cto.role, # Send to self to trigger processing, or directly to subordinate
        # Better: Send directly to VP Engineering
        content="Implement 'One-Click Checkout' in the Backend API.",
        message_type="TASK"
    ))
    
    # Let's actually send it directly to VP Engineering to start the chain from CTO
    vp_eng = bus.role_map["VP Engineering"]
    bus.route_message(Message(
        sender_id=cto.id,
        sender_role=cto.role,
        receiver_role="VP Engineering", 
        content="Implement 'One-Click Checkout' in the Backend API.",
        message_type="TASK"
    ))
    
    # 5. Simulation Loop
    tick = 0
    max_ticks = 45 # Increased for Rebrand
    
    # Audit Trigger Flag
    audit_triggered = False
    
    try:
        while tick < max_ticks:
            print(f"\n[Tick {tick}] Processing Agents...")
            
            # --- SCENARIO: TPM Audit Trigger at Tick 15 ---
            if tick == 15 and not audit_triggered:
                print("\n--- [SCENARIO] TPM 'Tom' Initiates Project Audit ---")
                tpm = bus.role_map.get("TPM - Core Platform")
                if tpm:
                    # TPM checks and finds 'Database Migration' missing
                    print(f"  [{tpm.role}] Checking GitHub... 'Database Migration' is MISSING.")
                    # TPM alerts Director of Engineering
                    missing_msg = Message(
                        sender_id=tpm.id,
                        sender_role=tpm.role,
                        receiver_role="Director of Engineering",
                        content="TASK_MISSING: Database Migration Scrips for Checkout",
                        message_type="TASK_MISSING"
                    )
                    bus.route_message(missing_msg)
                    audit_triggered = True

            # --- SCENARIO: Performance Alert at Tick 20 ---
            if tick == 20:
                print("\n--- [SCENARIO] Slow Query Alert Triggered ---")
                perf_eng = bus.role_map.get("Performance Engineer 1")
                if perf_eng:
                     print(f"  [{perf_eng.role}] DETECTED Slow Query on 'Orders' Table. Latency > 2s.")
                     # Alerts Manager
                     alert_msg = Message(
                        sender_id=perf_eng.id,
                        sender_role=perf_eng.role,
                        receiver_role="Director of Engineering", # Escalating to Dir to route to proper Manager
                        content="URGENT: Optimize Slow SQL Query on Checkout",
                        message_type="TASK"
                     )
                     bus.route_message(alert_msg)
            
                     bus.route_message(alert_msg)
            
            # --- SCENARIO: Scope Creep at Tick 5 ---
            if tick == 5:
                print("\n--- [SCENARIO] Product Manager Updates Requirements (Scope Creep) ---")
                pm = bus.role_map.get("Product Manager")
                if pm:
                    print(f"  [{pm.role}] GitHub Story Updated: 'Add Payment Split'. Notifying Engineering.")
                    scope_msg = Message(
                        sender_id=pm.id,
                        sender_role=pm.role,
                        receiver_role="Engineering Manager (Backend)",
                        content="Requirement Update: Add 'Split Payment' option to Checkout flow.",
                        message_type="REQ_CHANGE"
                    )
                    bus.route_message(scope_msg)

            # --- SCENARIO: Hiring Request at Tick 12 ---
            if tick == 12:
                print("\n--- [SCENARIO] Engineering Manager Requests New Hire ---")
                hiring_mgr = bus.role_map.get("Engineering Manager (Backend)")
                if hiring_mgr:
                    print(f"  [{hiring_mgr.role}] Team is scaling. Requesting Headcount.")
                    # Simulate Manager sending request to Director (handled by auto-routing in HEADCOUNT_REQUEST logic if we just set receiver to reports_to)
                    # For clarity, we'll manually start the chain or let the agent logic handle it.
                    # Based on my msg logic: 'if "Manager" in self.role: return Message(..., self.reports_to, ...)'
                    # So I just need to inject the intial intent into the Manager? 
                    # No, I should simulate the Manager *sending* it.
                    
                    req_msg = Message(
                        sender_id=hiring_mgr.id,
                        sender_role=hiring_mgr.role,
                        receiver_role="Director of Engineering", # Send to Director
                        content="Requesting 1 Headcount: Junior Backend Developer",
                        message_type="HEADCOUNT_REQUEST"
                    )
                    bus.route_message(req_msg)

            # --- SCENARIO: COO Process Health Audit at Tick 18 ---
            if tick == 18:
                print("\n--- [SCENARIO] COO 'Edward' Initiates Operational Audit ---")
                coo = bus.role_map.get("COO")
                if coo:
                    print(f"  [{coo.role}] Starting Company-Wide Process Health Check...")
                    # Broadcast to all VPs
                    vps = [agent.role for agent in agents if "VP" in agent.role]
                    for vp_role in vps:
                        check_msg = Message(coo.id, coo.role, vp_role, "REPORT STATUS", "PROCESS_HEALTH_CHECK")
                        bus.route_message(check_msg)

            # --- SCENARIO: Customer Support Ticket at Tick 25 ---
            if tick == 25:
                print("\n--- [SCENARIO] User Reports Critical Bug to Support ---")
                support_agent = bus.role_map.get("Support Agent 1")
                if support_agent:
                    print(f"  [{support_agent.role}] Received Ticket #101 via Email.")
                    # Simulate fake customer message by creating a direct input message
                    ticket_msg = Message(
                        sender_id="customer_001", # Fake ID
                        sender_role="Customer",   # Fake Role
                        receiver_role=support_agent.role,
                        content="Error/Crash: 500 Server Error when logging in via Mobile App.",
                        message_type="CUSTOMER_TICKET"
                    )
                    # We can't route from non-agent easily in this bus logic unless we fake inject it.
                    # Or we just have the agent 'process' it as if it appeared in inbox. 
                    # Simpler: Support Agent generates it or we route it 'from' a system agent?
                    # Let's just route it. BaseAgent doesn't validate sender existence in registry for receiving.
                    bus.route_message(ticket_msg)

            # --- SCENARIO: Massive Marketing Campaign at Tick 30 ---
            if tick == 30:
                print("\n--- [SCENARIO] CMO Launches Global Marketing Campaign 'V2.0' ---")
                cmo = bus.role_map.get("CMO")
                if cmo:
                     # CMO broadcasts to Directors
                     campaign_msg = Message(cmo.id, cmo.role, "VP Marketing", "Launch Strategy V2.0: 'Future of Code'", "MARKETING_CAMPAIGN")
                     bus.route_message(campaign_msg)
                     bus.route_message(campaign_msg)

            # --- SCENARIO: User Research Study at Tick 36 ---
            if tick == 36:
                print("\n--- [SCENARIO] Head of Research Initiates Usability Study ---")
                researcher = bus.role_map.get("UX Researcher")
                if researcher:
                     # Simulate self-starting research
                     bus.route_message(Message(researcher.id, researcher.role, researcher.role, "Analyze Onboarding Flow", "USER_RESEARCH"))

            # --- SCENARIO: VP Design Triggers Holistic Rebrand at Tick 40 ---
            if tick == 40:
                print("\n--- [SCENARIO] VP Design Requests 'Holistic Rebrand' ---")
                vp_design = bus.role_map.get("VP Design")
                if vp_design:
                     bus.route_message(Message(vp_design.id, vp_design.role, "Creative Director", "New Corporate Identity", "ASSET_REQUEST"))
            # Everyone checks their inbox and replies
            all_new_messages = []
            
            # Shuffle agents to avoid order bias
            random.shuffle(agents)
            
            for agent in agents:
                outbox = agent.process_inbox()
                all_new_messages.extend(outbox)
                
            # Route new messages
            if not all_new_messages:
                print("No new messages this tick.")
            else:
                for msg in all_new_messages:
                    print(f"  -> Routing msg: {msg.sender_role} -> {msg.receiver_role} [{msg.message_type}]")
                    bus.route_message(msg)
            
            time.sleep(1) # Sleep for readability
            tick += 1
            
        print("\n--- Simulation Ended ---")

    except KeyboardInterrupt:
        print("Simulation stopped.")

if __name__ == "__main__":
    main()
