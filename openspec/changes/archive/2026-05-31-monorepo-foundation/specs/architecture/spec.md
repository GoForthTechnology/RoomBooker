## MODIFIED Requirements

### Requirement: Presentation Layer
The presentation layer SHALL be located in the primary application package (e.g., `packages/roombooker_portal/lib/ui/`) and SHALL follow a widget-based composition.

#### Scenario: Verify UI Structure
- **WHEN** adding a new screen to the Portal
- **THEN** it is placed in `packages/roombooker_portal/lib/ui/screens/`

### Requirement: Domain Layer
The domain layer SHALL contain entities and business logic, independent of external services, and SHALL be located in the `roombooker_core` package.

#### Scenario: Verify Entity Location
- **WHEN** defining a data model
- **THEN** it is placed in `packages/roombooker_core/lib/data/entities/`
