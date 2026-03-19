import { ComponentFixture, TestBed } from '@angular/core/testing';

import { Playerfield } from './playerfield';

describe('Playerfield', () => {
  let component: Playerfield;
  let fixture: ComponentFixture<Playerfield>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Playerfield]
    })
    .compileComponents();

    fixture = TestBed.createComponent(Playerfield);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
