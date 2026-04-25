# Bryte Assist UI Framework SDK

## Overview
The Bryte Assist UI Framework SDK allows applications to integrate the Bryte Assist experience. The Bryte SDK provides a way for an application to load Bryte Assist from any UI framework. The application can provide where the Bryte Assist search window is initially displayed when opened. The Bryte SDK supports a method for the Containing Application to communicate with Bryte Assist and Bryte Intents by dispatching actions and receiving transitional events like opened and closed from Bryte Assist. Additionally, Bryte Intents can communicate back to the application through shared application state.

## Installation
To integrate with Bryte Assist, download the SDK from the URL below. This provides the ability to use BryteAssistShellComponent.

```
https://suitex-bryte-sdk-dev.cdn.ultiproservices.com/dev/latest/bryte-sdk-shell-element.js
```

## Demo Application
https://github.com/UKGEPIC/ukg-bryte-assist-shell

## BryteAssistShellComponent

To bootstrap Bryte Assist, a Web Component called BryteAssistShellComponent is added to the Containing Application's HTML template.

```html
<!DOCTYPE html>
<html>
  <head>
    <title>UKG Application</title>
    <!-- Applications should get the CDN path from TRex service code h-pexp-sxssdkcdn -->
    <script async type="module" src="https://suitex-bryte-sdk-dev.cdn.ultiproservices.com/dev/latest/bryte-sdk-shell-element.js"></script>
  </head>
  <body>
    <ukg-app class="full-screen">
      <nav-bar>...</nav-bar>
      <app-content>...</app-content>
      <!-- search-dispatch-url: get from TRex service code h-pexp-sxsgtwext -->
      <!-- static-asset-url: get from TRex service code h-pexp-sxsuicdn -->
      <ukg-bryte-assist-shell
        #myBryteAssist
        headers='{
          "Authorization": "Bearer my_auth_token",
          "X-Custom-Header": "Value"
        }'
        ld-fields='{
          "userId": "user123",
          "environment": "development",
          "dataCenter": "us-east-1"
        }'
        locale="en-US"
        locale-date-format="PP"
        locale-time-format="p"
        search-dispatch-url="https://suitex-search-dev.ultiproservices.com"
        user='{
          "id": "user123",
          "fullName": "John Doe",
          "email": "john.doe@example.com",
          "initials": "JD",
          "locale": "en-CA",
          "preferredName": "Johnny",
          "gmtOffset": -5,
          "photoUrl": "https://example.com/user_photo.jpg"
        }'>
      </ukg-bryte-assist-shell>
    </ukg-app>
  </body>
</html>
```

The SDK is loaded from the Bryte Assist SDK CDN within `bryte-sdk-shell-element.js`. Applications should get the CDN path from TRex service code `h-pexp-sxssdkcdn`.

The HTML tag `ukg-app` defines the Containing Application and `ukg-bryte-assist-shell` (BryteAssistShellComponent) defines the Bryte SDK Web Component. `ukg-bryte-assist-shell` is added as a child element. When rendered, Bryte Assist is loaded.

## Shell Properties

| Property | Attribute | Description | Type | Default |
|----------|-----------|-------------|------|---------|
| enableVoice | enable-voice | Supports voice input (voice + keyboard modes) | boolean | false |
| headers | headers | Headers for integration with Bryte Assist | object | |
| ldFields | ld-fields | Fields for Launch Darkly feature flags | LDFields | |
| locale | locale | Locale the containing app is using | string | 'en-US' |
| localeDateFormat | locale-date-format | Date display pattern (date-fns) | string | |
| localeTimeFormat | locale-time-format | Time display pattern (date-fns) | string | |
| platform | platform | Platform: 'web' \| 'mobile' | string | |
| searchDispatchUrl | search-dispatch-url | Path where requests are sent | string | |
| staticAssetUrl | static-asset-url | Path where Bryte Assist loads from (INTERNAL) | string | |
| user | user | User profile info for conversation display | UserProfile | |

### LDFields Definition

| Property | Type | Condition | Description |
|----------|------|-----------|-------------|
| dataCenter | string | optional | Current data center |
| environment | string | optional | Current environment |
| userId | string | required | User identifier |

### UserProfile Definition

| Property | Type | Condition | Description |
|----------|------|-----------|-------------|
| dateFormat | string | optional | Date format (date-fns) |
| email | string | optional | User email |
| fullName | string | optional | User full name |
| gmtOffset | number | optional | GMT offset for timezone |
| id | string | optional | User identifier |
| initials | string | optional | User initials |
| locale | string | optional | User locale. Default: en-US |
| photoUrl | string | optional | User photo path (data url or full path) |
| preferredName | string | optional | Preferred name |
| timeFormat | string | optional | Time format (date-fns) |
| userIntegrationKey | string | optional | GUID for integration purposes |

## TRex Service Codes (URLs)

| Property | Service Code | Description |
|----------|-------------|-------------|
| searchDispatchUrl | h-pexp-sxsgtwint | Internal search dispatcher |
| searchDispatchUrl | h-pexp-sxsgtwext | External search dispatcher |
| staticAssetUrl | h-pexp-sxsuicdn | Bryte Assist CDN |
| SDK CDN | h-pexp-sxssdkcdn | Bryte Assist SDK CDN |

It is the Containing Application's responsibility to provide URLs using these service codes.

**Example (UKG Pro):**
```
searchDispatchUrl = /handlers/WayfindingHomeHubProxy.ashx/Experience.Search.Api
```
UKG Pro maps legacy service code `Experience.Search.Api` to TRS internal code `h-pexp-sxsgtwint` via a proxy.

## Shell Events

| Event | Type | Value | Description |
|-------|------|-------|-------------|
| viewState | string | 'closed' \| 'opened' \| 'openedFullScreen' | Display state |
| persons | string[] | List of person identifiers | Persons referenced in conversation |
| navigation | Navigation | | Navigation request |

Events are accessible from the shared store.

### ViewState Values

| Value | Description |
|-------|-------------|
| closed | Bryte Assist has closed |
| opened | Bryte Assist has opened |
| openedFullScreen | Bryte Assist has opened full screen |

Mapped into shared store as `bryteView`.

### Person Event Values

| Value | Description |
|-------|-------------|
| `<pro.coid>@<pro.eeid>` | UKG Pro persons |
| `<wfm.personid>` | UKG WFM persons |
| `<avatar id>` | Other containing app persons |

Mapped into shared store as `persons`. Accumulates over conversation. Change detection on additions.

### Navigation Definition

| Property | Type | Description |
|----------|------|-------------|
| link | object | Navigation link info for containing app |
| timestamp | number | Unix epoch time |

Mapped into shared store as `navigation`. Change detection on timestamp difference.

To observe `bryteView`, `persons`, and `navigation`, call `BryteAssistShellComponent.select`.

## Shell Methods

| Method | Returns | Description |
|--------|---------|-------------|
| dispatch | Promise\<boolean\> | Send action to Bryte Assist / Bryte Intent |
| init | Promise\<boolean\> | Initialize with Bryte Assist |
| links | Promise\<boolean\> | Provide navigation links |
| locate | Promise\<boolean\> | Change position/size |
| select | Observable | Observe shared store changes |

### Angular Example

```typescript
import { AfterViewChecked, Component, ElementRef, ViewChild } from '@angular/core';

@Component({
  selector: 'ukg-app',
  templateUrl: './ukg-app.component.html',
  styleUrls: ['./ukg-app.component.scss']
})
export class UkgAppComponent implements AfterViewChecked {
  private myBryteAssistInst: any;

  @ViewChild('myBryteAssist', { static: false }) myBryteAssist: ElementRef;

  ngAfterViewChecked() {
    if (this.myBryteAssist && !this.myBryteAssistInst) {
      this.myBryteAssistInst = this.myBryteAssist.nativeElement || {};

      if (this.myBryteAssistInst.init) {
        this.myBryteAssistInst
          .init({ applicationId: 'sampleApp' })
          .then(success => console.log(`myBryteAssist.init ${success ? "succeeded" : "failed"}`));
      } else {
        console.error('Problem rendering ukg-bryte-assist Web Component');
      }
    }
  }
}
```

## Method Details

### avatars — Send employee pictures

```typescript
avatars(items: Avatar[]): Promise<boolean>
```

| Property | Type | Condition | Description |
|----------|------|-----------|-------------|
| id | string | required | Person identifier |
| avatarUrl | string | required | Picture URL (data url or fully resolved path on same domain) |

### dispatch — Send action to Bryte Assist

```typescript
dispatch(params: BryteDispatchParams): Promise<boolean>
```

When dispatching, Bryte Assist auto-opens in copilot view. Returns true if successful.

#### BryteDispatchParams

| Property | Type | Condition | Description |
|----------|------|-----------|-------------|
| actionResponder | string | optional | Responder for this action. Requires `handler` |
| displayLabel | boolean | optional | Display label in conversation. Default: true |
| handler | object | optional | Intent action definition |
| id | string | required | Action ID |
| label | string | required | Action description |

**Two modes:**
- **Agent Lock Mode** — `handler` + `actionResponder` provided → dispatched directly to the Bryte Intent identified by `actionResponder`. Bypasses NLU.
- **Dispatch Mode** — uses `label` to submit conversation query through classification.

### init — Initialize with Bryte Assist

```typescript
init(params: BryteInitParams): Promise<boolean>
```

Called when application page initially loads. Returns true if successful.

#### BryteInitParams

| Property | Type | Condition | Description |
|----------|------|-----------|-------------|
| applicationId | string | required | Unique app identifier |
| conversationId | string | optional | Conversation to restore |
| displayChat | string | optional | View state after init: 'close' \| 'open' \| 'openFullScreen'. Default: 'close' |
| inputMode | string | optional | Input mode when enableVoice=true: 'keyboard' \| 'voice'. Default: 'keyboard' |
| location | Location | optional | Initial position/size |
| mxSupported | boolean | optional | MX framework support. Default: false |
| store | object | optional | Shared store with Bryte Assist |
| topics | BryteDispatchParams[] | optional | Welcome prompt suggestions |

#### Location Definition

| Property | Type | Condition | Description |
|----------|------|-----------|-------------|
| attach | Attach | required | Which side to attach to |
| inline | boolean | optional | Side-by-side (true) or overlay (false). Default: false |
| minimizeOffset | Position | optional | FAB button position when minimized (offset from bottom-right) |
| size | string | optional | Width/height based on attach side. Supports px, rem, em, % |

#### Attach Enumeration

| Key | Value |
|-----|-------|
| BOTTOM | bottom |
| LEFT | left |
| RIGHT | right |
| TOP | top |

#### Position Definition

| Property | Type | Description |
|----------|------|-------------|
| horizontal | number | Horizontal offset. Default: 0 |
| vertical | number | Vertical offset. Default: 0 |

### links — Navigation links

```typescript
links(items: NavLink[]): Promise<boolean>
```

#### NavLink Definition

| Property | Type | Condition | Description |
|----------|------|-----------|-------------|
| link | Link | required | Link definition for Bryte Intents |
| original | object | required | Navigation link info for containing app |

#### Link Definition

| Property | Type | Condition | Description |
|----------|------|-----------|-------------|
| id | string | required | Link identifier |
| label | string | required | Link description |
| parentLabel | string | optional | Parent link description |
| secondary | string[] | optional | Additional descriptions |
| url | string | optional | Link navigation URL |

### page — Identify current application page

```typescript
page(params: BrytePageParams): Promise<boolean>
```

#### BrytePageParams

| Property | Type | Condition | Description |
|----------|------|-----------|-------------|
| headers | object | optional | Updated headers for integration |
| title | string | optional | Page title. Forwarded to Bryte Intents via `X-Page-Title` header |

### select — Observe shared store changes

```typescript
select(params: BryteSelectParams): Observable
```

#### BryteSelectParams

| Property | Type | Condition | Description |
|----------|------|-----------|-------------|
| applicationId | string | optional | App identifier. Default: containing app ID |
| key | string | required | Dot-notation path into shared store |

### view — Change view, position, and size

```typescript
view(params: BryteViewParams): Promise<boolean>
```

#### BryteViewParams

| Property | Type | Condition | Description |
|----------|------|-----------|-------------|
| displayChat | string | required | 'close' \| 'open' \| 'openFullScreen' |
| location | Location | optional | Position/size. Defaults to init location |

## Additional Topics
- Datadog integration
