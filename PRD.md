# Intestease Product Requirements Document

Intestease is a mobile-first app designed for people with Crohn's disease to better understand and manage their condition. The core idea is simple: track daily symptoms and food intake, learn what triggers flare-ups, and eventually predict when a flare is likely to happen before it actually does.

Most existing tools are either too manual or don't give meaningful insights. Intestease aims to fix that by combining structured tracking with a smart system that actually learns from the user over time and gives helpful, proactive guidance.

## What We're Trying to Solve

People with Crohn's deal with a lot of uncertainty. Flare-ups can feel random, and it's hard to know what actually causes them. Even if someone tracks their symptoms or diet, it's usually scattered across notes apps or not analyzed in a useful way.

The goal of this app is to:
* Make daily tracking easy enough that people actually stick with it
* Turn that data into clear, personalized insights
* Predict flare risk in a way that feels understandable and useful
* Help users make better day-to-day decisions

## Target Users

* People diagnosed with Crohn's disease (primary focus)
* Potential future expansion to IBS or ulcerative colitis
* Possibly caregivers later on

## Core Idea

At the center of the app is a flare risk system.

Instead of just logging data, the app continuously answers:

How likely am I to have a flare soon, and why?

Everything in the app feeds into that:
* Symptoms
* Food
* History
* Patterns over time

## Main Features

### 1. Home Screen

This is the most important screen in the app.

At the top, there's a circular visualization that shows:
* A risk percentage (like 72%)
* A time window (for example, "next 24-48 hours")
* A short explanation of what's driving the risk

Below that, there are simple cards:
* Today's symptoms
* Today's meals

And quick buttons to:
* Log symptoms
* Log food

If you scroll down, you'll see:
* Tips
* Insights
* Recommendations based on your data

#### Home Screen - Circular Risk Component (SDK Integration)

The top section of the home screen must use a custom circular UI component provided via SDK.

This component is based on a rotating circular text + hover-reveal interaction (see provided component file: circular-reveal-heading.tsx).

Requirements:
* The component must be placed at the top of the home screen as the primary visual element.
* It replaces a standard progress circle or chart.

Modifications to the SDK:
The default demo content must be replaced with flare-related data:

Text segments (outer ring):
* LOW RISK
* MODERATE
* HIGH RISK
* TRIGGERS

Center content (dynamic):
* Risk percentage (e.g., "72%")
* Time prediction (e.g., "Next 24-48 hrs")

Behavior:
* Rotates continuously (as implemented)
* On hover/tap: Shows relevant visuals (can be placeholder images initially)
* Must update dynamically based on prediction engine output

Styling Changes:
* Replace neutral gray theme with:
  * Red tones for high risk
  * Green tones for low risk
* Maintain soft shadows and rounded aesthetic
* Keep animation behavior from SDK (Framer Motion)

Technical Notes:
* File must be placed in: /components/ui/circular-reveal-heading.tsx
* Requires: framer-motion, Tailwind CSS, shadcn/ui structure
* Component should accept dynamic props: riskScore, riskLevel, explanation (optional for future use)

Integration:
* This component is the primary indicator of system state
* Must re-render whenever:
  * User logs symptoms
  * User logs food
  * Background prediction updates occur

### 2. Symptom Tracking

Symptoms are logged through a card-based interface.

Each symptom can be expanded and rated on a scale from 1 to 10, with labels:
* 1-3: mild
* 4-6: moderate
* 7-10: severe

We track things like:
* Abdominal pain
* Diarrhea
* Fatigue
* Nausea
* Bloating
* etc.

There's also a natural language description field where users describe how they're feeling. This isn't just a free-text box - it's structured for the ML model. The output is formatted as:

`[symptom_type | severity:N | time_of_day] user description`

The prediction engine parses these descriptions for keywords that signal worsening (severe, constant, spreading) or improvement (mild, manageable, improving) and factors them into the risk score.

Over time, the app adapts:
* Frequently logged symptoms show up first
* It may suggest symptoms based on past patterns

### 3. Food Logging

Food logging is structured (not just free text).

The flow is simple:
* Enter what you ate
* Select tags (dairy, gluten, spicy, etc.)
* Add portion size
* Choose meal type

Later, the app prompts for a reaction:
* Comfort score (1-5)

The UI starts simple and expands as needed so it doesn't feel overwhelming.

### 4. Calendar

The calendar gives a visual overview of everything.

You can:
* Tap any day to view or edit logs
* See flare days, symptom severity, and food reactions

It also highlights patterns over time, like:
* "Flares seem to happen every few days"
* "This flare likely started here"

Users can also quickly add entries directly from the calendar.

### 5. Analytics

This is where everything comes together.

At the top, there's a short AI-generated summary, like:
"Your risk increased this week due to high-fat meals and fatigue spikes."

Below that:
* Charts for symptoms, risk, and flare frequency
* Trigger insights (e.g., "Dairy increases your flare risk")
* Recommendations (e.g., "Avoid heavy meals for the next 48 hours")

### 6. AI Assistant

The app includes an AI assistant that's available throughout the experience.

It can:
* Answer Crohn's-related questions
* Explain why your risk is high
* Suggest what to do next

It's not just a chatbot, it's integrated into the app's logic.

### 7. Flare Detection

The app helps identify flares automatically.

If symptoms spike or patterns match past flares, it will suggest:
"This looks like a flare"

The user confirms or rejects it, and the system learns from that over time.

### 8. Flare Prediction

This is the core system behind everything.

We'll build it in stages:

Stage 1 (initial):
* A weighted system based on symptoms, food, and recent history

Stage 2:
* Conditional probability model:
  * P(Flare | symptoms, food, history)

Stage 3 (later):
* Time-series model (like LSTM) for more accurate predictions

The output always includes:
* Risk percentage
* Time estimate
* Short explanation

### 9. Notifications

The app is proactive, not passive.

It sends:
* Daily reminders to log
* Alerts if risk is increasing
* Suggestions like:
  * "Avoid dairy today"
  * "You haven't logged in a while"

---

## 10. From Prediction to Prevention

This is the next evolution of Intestease.

Everything described above - the tracking, the risk scoring, the AI assistant - is the foundation. But predicting a flare is only useful if you can actually do something about it. That's where prevention comes in.

A recent study from the Crohn's & Colitis Foundation found that 93% of patients are interested in predictive testing and prevention. And when given the choice, most people strongly prefer lifestyle-based interventions - changes to food, stress, sleep, hydration - over adding more medication.

That insight changes how the app should behave. The goal isn't just to say "your risk is high." The goal is to help you bring it down.

### Prevention Mode

When flare risk crosses into moderate or high territory, the app should shift its posture. Instead of just showing a number and an explanation, it enters Prevention Mode - a guided intervention that tells the user exactly what they can do right now to reduce their risk.

This includes:
* Foods to avoid today, based on their personal trigger history
* Safer alternatives they've eaten before without issues
* Behavioral nudges: drink more water, prioritize rest, try a stress-reduction technique

The key is that this should feel like a plan, not a panic button. The tone should be calm, specific, and actionable. "You've had dairy twice this week and your risk is climbing. Consider skipping it today. Here are meals that worked well for you last week."

Prevention Mode isn't a separate screen. It transforms the home screen experience when risk is elevated - the circular display shifts, the tips section becomes prescriptive, and the quick actions prioritize safe choices.

### Scenario Simulator

One of the most powerful things we can build on top of the prediction model is a "what if" tool.

Users should be able to ask:
* "What happens if I eat dairy today?"
* "What if I skip dinner?"
* "What if I have a stressful day?"

The app runs that scenario through the same prediction engine and shows how the risk score would change. For example:

> "If you eat dairy today, your estimated flare risk increases from 34% to 56% based on your past 30 days of data."

This isn't about being prescriptive. It's about giving people the information to make their own decisions. Some days, eating the thing you want is worth the risk. But at least now you know what the risk actually is.

The simulator should be accessible from the AI assistant ("What happens if...") and eventually as a standalone feature on the home screen or food logging flow.

### Better Risk Explanations

One thing that kills trust in health apps is vague outputs. "Your risk is moderate" doesn't mean much if you don't know why.

Every risk score should come with a clear, data-driven explanation tied to the user's own history. Not generic medical advice - their actual data.

Examples:
* "Dairy increased your flare probability by 22% based on 14 past entries where you consumed dairy and logged symptoms within 48 hours."
* "Your risk is elevated because your symptom severity has trended upward for 3 consecutive days, which matched the pattern before your last two flares."
* "Your natural language descriptions over the past 24 hours contain keywords associated with pre-flare states: 'constant', 'getting worse', 'can't sleep'."

Transparency builds trust. If users understand why the system is saying what it's saying, they're more likely to act on it.

### Pre-Flare Detection

Flare detection as described in section 7 catches flares that are already happening. But there's a gap between "everything's fine" and "you're in a flare."

That gap is the pre-flare window - a period where symptoms start shifting, patterns start forming, and the body is signaling that something is coming. Most people don't notice it until it's too late.

The app should identify this phase and surface it explicitly:

> "You may be entering a pre-flare phase. Your symptoms have shifted over the past 48 hours in a way that preceded your last 3 flares. This is the best time to intervene."

This isn't the same as a high risk score. A risk score is probabilistic. Pre-flare detection is pattern-based - it looks at the shape of symptom trajectories, not just the numbers. It answers: "Does this look like what happened last time, right before things got bad?"

When pre-flare is detected, Prevention Mode should activate automatically.

### Daily Optimization Plan

Every morning (or whenever the user opens the app), they should see a short, personalized plan for the day. Not a lecture - just two or three things that would help.

Examples:
* "Avoid high-fat foods today - your gut has been sensitive this week."
* "Prioritize rest tonight. Your fatigue scores have been climbing."
* "Stay hydrated. You logged dehydration-related symptoms yesterday."

These are generated from the prediction model, the user's recent logs, and their known triggers. They should feel like a coach, not a doctor.

The plan updates throughout the day as the user logs new data. If they log a trigger food at lunch, the afternoon plan might shift: "You had dairy at lunch. Consider keeping dinner light and easy to digest."

### Risk Reduction Feedback

This is the piece that closes the loop and makes the whole system feel rewarding.

After a day where the user followed recommendations or made good choices, the app should tell them:

> "You reduced your flare risk by 18% today by avoiding trigger foods and staying hydrated."

Or over a longer period:

> "This week, your average risk was 23% lower than last week. Your food choices made the biggest difference."

This does two critical things:
1. It proves the system works - the user can see that their actions have measurable impact
2. It reinforces positive behavior - people stick with habits when they can see results

Risk reduction feedback should appear on the home screen, in the analytics dashboard, and occasionally as a notification: "Nice work today. Your risk dropped 12 points."

### Future Direction

A few things we want to explore down the road, once the prevention system is solid:

* **Family risk tracking** - Some users want to track patterns for family members, especially parents managing a child's Crohn's. This opens up shared dashboards and caregiver views.
* **Long-term prevention modeling** - Instead of just day-to-day risk, build models that predict risk over weeks or months. "If you maintain this diet pattern, your estimated flare frequency drops from once every 3 weeks to once every 6 weeks."

These are longer-term bets, but they follow naturally from the prevention-first approach.

---

## 11. Reducing Real-World Health Burden

Everything above focuses on prediction and prevention at the individual level. But there's a bigger picture worth addressing: the real-world health burden that Crohn's disease places on patients and the healthcare system.

CDC data shows that IBD patients have significantly higher rates of ER visits, hospitalizations, and surgeries compared to the general population. They also carry a disproportionate mental health burden - anxiety and depression are common, and they compound the physical symptoms. The financial cost is substantial. And yet, as the Crohn's & Colitis Foundation found, 93% of patients are actively interested in predictive testing and prevention, and most prefer lifestyle-based interventions over additional medication.

Intestease is positioned to address this directly. Not by replacing clinical care, but by giving people tools that reduce the frequency and severity of the events that drive those numbers up.

### Mental Health Integration

Stress, anxiety, and mood aren't separate from gut health - they're deeply connected. The app should track mental state alongside physical symptoms, not as a secondary feature but as a first-class input to the prediction engine.

This means:
* Daily mood and stress check-ins alongside symptom logging
* Anxiety tracking as a variable in the flare risk model
* Insights that connect the dots: "Your flare risk increases 35% during high-stress periods"
* Trend views that overlay mental health data with symptom timelines

This isn't a replacement for therapy or clinical mental health support. It's a layer of awareness that helps users see how their mental state interacts with their condition - something most people with Crohn's suspect but can't quantify.

### Hidden Pattern Detection

People are good at noticing obvious triggers. If dairy causes problems every time, they'll figure that out. But most real-world patterns are more subtle - they involve combinations, timing, and context that are hard to spot manually.

The app should actively detect patterns users might miss:
* Cross-referencing food combinations, timing gaps, sleep quality, stress levels, and even weather
* Surfacing non-obvious correlations: "Your symptoms tend to worsen 2 days after high-stress periods combined with dairy"
* Flagging delayed reactions that users wouldn't naturally connect to a cause
* Making invisible correlations visible through clear, data-backed explanations

The prediction engine already processes this data. This feature is about surfacing the intermediate findings - the "why behind the why" - so users build a deeper understanding of their own patterns.

### Flare Severity Prediction

Knowing a flare is coming is valuable. Knowing how bad it might be changes what you do about it.

The app should predict not just flare likelihood but expected severity:
* Mild: manageable with rest and diet adjustments
* Moderate: may need medication changes or a day off
* Severe: consider contacting your care team

This helps users make proportional decisions. A mild predicted flare might mean skipping a trigger food. A severe one might mean rescheduling plans or reaching out to a doctor early. The output should be clear and actionable: "Your current pattern suggests a moderate-severity flare if no intervention is taken."

### Healthcare Impact Layer

Flare risk scores are abstract. Connecting them to real-world healthcare outcomes makes them tangible.

Using CDC data on IBD healthcare utilization, the app can map risk levels to concrete probabilities:
* How elevated risk correlates with ER visit likelihood
* The relationship between sustained high-risk periods and hospitalization
* How early intervention reduces the chance of acute care

The messaging should be grounding, not alarming: "Reducing your risk today may lower your chance of acute care this week." The goal is to make the cost of inaction concrete and the value of prevention measurable - not to scare people, but to motivate them with real stakes.

### Long-Term Impact Feedback

Day-to-day feedback is important (covered in Risk Reduction Feedback above), but users also need to see the bigger picture. Small daily choices compound, and the app should make that visible.

This includes:
* Weekly and monthly impact summaries: "You reduced your predicted health burden by 28% this month"
* Flare frequency trends: "Your flare frequency dropped from once every 2 weeks to once every 5 weeks"
* Long-term behavior change tracking: which habits stuck, which made the biggest difference
* Cumulative risk reduction over time

This is the feature that turns Intestease from a daily tool into a long-term companion. When someone can see that three months of consistent tracking and mindful choices cut their flare frequency in half, they don't need external motivation to keep going.

### Future Direction (Extended)

Building on the future directions outlined in Section 10, the health burden reduction layer opens up additional possibilities:

* **Family risk tracking for caregivers** - Parents managing a child's Crohn's or partners supporting a loved one need visibility into patterns and predictions. Shared dashboards with appropriate privacy controls.
* **Long-term disease prevention modeling** - Extending the prediction horizon from days to months and years. "If you maintain this pattern, your projected annual flare count drops from 12 to 5."
* **Integration with clinical markers** - Connecting app data with lab results like CRP and calprotectin levels for higher-accuracy predictions and better collaboration with care teams.
* **Wearable stress and sleep data feeds** - Pulling continuous data from Apple Watch, Fitbit, or Oura Ring to improve stress and sleep inputs without manual logging.

These extensions move Intestease closer to a comprehensive disease management platform - one that bridges the gap between daily self-care and clinical outcomes.

---

## Onboarding

When a user signs up, we collect enough information to personalize the experience early on:
* Basic info (age, gender, diagnosis)
* Disease severity
* Known triggers
* Diet type
* Stress and sleep
* Flare history

## Design Style

The app should feel:
* Clean and simple
* Easy to use even when someone isn't feeling well

Design details:
* Rounded components
* Soft shadows
* Large, readable text

Colors:
* Green (#CAF1DF) for safe states
* Red for risk and alerts
* Neutral background

## Technical Direction

Frontend:
* React Native (or mobile-first web)
* Tailwind + shadcn components
* Framer Motion for animations

Backend:
* Supabase or Firebase

ML:
* Python backend (FastAPI)
* Models served via API

## Data Structure (Simplified)

We'll store:
* Users
* Daily logs (symptoms + meals)
* Flare events
* Predictions

Everything is structured so it can be used for ML later.

## Future Plans

* Doctor-facing dashboard
* Shareable reports
* Wearable integrations
* More advanced prediction models

## Risks / Challenges

* Making predictions accurate early on (cold start problem)
* Avoiding overwhelming the user with too much logging
* Handling sensitive health data properly
* Making sure insights feel trustworthy

## MVP Scope

We're not doing a stripped-down MVP.

The goal is to build a complete first version that includes:
* Prediction system
* AI assistant
* Adaptive logging
* Advanced analytics
* Smart notifications

## Final Note

This app only works if:
1. Users consistently log data
2. The app gives real, useful feedback

Everything should be designed around making those two things happen.
