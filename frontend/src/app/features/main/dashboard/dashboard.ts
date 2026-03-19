import { Component, inject } from '@angular/core';
import format from '../../../shared/format.shared.json';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { CommonModule } from '@angular/common';


const formats = format.formats;

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [ReactiveFormsModule, CommonModule],
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.scss',
})
export class Dashboard {
  private fb = inject(FormBuilder);

  gameForm: FormGroup;
  readonly formats = formats;
  readonly playerCountOptions = [2, 3, 4, 5, 6] as const;

  constructor() {
    this.gameForm = this.fb.group({
      format: [this.formats[0]?.name ?? ''],
      roomName: [''],
      playerCount: [2, [Validators.required, Validators.min(2)]],
    });
  }

  selectPlayerCount(count: number) {
    this.gameForm.patchValue({ playerCount: count });
  }

  onSubmitGame() {

  }
}
